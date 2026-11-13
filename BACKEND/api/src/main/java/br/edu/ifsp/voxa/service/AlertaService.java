package br.edu.ifsp.voxa.service;

import br.edu.ifsp.voxa.dto.AlertaDtos.AlertaEvento;
import br.edu.ifsp.voxa.dto.AlertaDtos.AlertaMensagem;
import br.edu.ifsp.voxa.exception.RecursoNaoEncontradoException;
import br.edu.ifsp.voxa.exception.RegraNegocioException;
import br.edu.ifsp.voxa.model.AlertaEmergencia;
import br.edu.ifsp.voxa.model.Perfil;
import br.edu.ifsp.voxa.model.StatusAlerta;
import br.edu.ifsp.voxa.model.Usuario;
import br.edu.ifsp.voxa.repository.AlertaEmergenciaRepository;
import br.edu.ifsp.voxa.sms.SmsGateway;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Requisito funcional WebSocket (RF10 / BRADWBK CR8): o paciente aciona o
 * botão de emergência, o servidor grava o alerta, envia SMS ao telefone
 * cadastrado do responsável e publica cada mudança de status em
 * /topic/alertas/{perfilId} (app e painel web do cuidador recebem na hora).
 */
@Service
public class AlertaService {

    private final AlertaEmergenciaRepository alertas;
    private final PerfilService perfilService;
    private final SmsGateway sms;
    private final SimpMessagingTemplate broker;

    public AlertaService(AlertaEmergenciaRepository alertas, PerfilService perfilService,
                         SmsGateway sms, SimpMessagingTemplate broker) {
        this.alertas = alertas;
        this.perfilService = perfilService;
        this.sms = sms;
        this.broker = broker;
    }

    public static String topico(UUID perfilId) {
        return "/topic/alertas/" + perfilId;
    }

    @Transactional
    public AlertaEvento processar(AlertaMensagem msg) {
        Perfil perfil = perfilService.buscar(msg.perfilId());
        Usuario usuario = perfil.getUsuario();
        if (!usuario.getId().equals(msg.usuarioId())) {
            throw new RegraNegocioException("O perfil não pertence ao usuário informado");
        }

        AlertaEmergencia alerta = new AlertaEmergencia();
        alerta.setClienteId(msg.clienteId());
        alerta.setUsuario(usuario);
        alerta.setPerfil(perfil);
        alerta.setMensagem(msg.mensagem() == null || msg.mensagem().isBlank()
                ? "ALERTA VOXA: " + perfil.getNome() + " acionou o botão de emergência e precisa de ajuda."
                : msg.mensagem());
        alerta.setTelefoneDestino(usuario.getTelefone());
        alertas.save(alerta);
        publicar(alerta);

        boolean enviado = usuario.getTelefone() != null && !usuario.getTelefone().isBlank()
                && sms.enviar(usuario.getTelefone(), alerta.getMensagem());
        alerta.setStatus(enviado ? StatusAlerta.SMS_ENVIADO : StatusAlerta.SMS_FALHOU);
        return publicar(alerta);
    }

    @Transactional(readOnly = true)
    public List<AlertaEvento> historico(UUID perfilId) {
        return alertas.findTop50ByPerfilIdOrderByCriadoEmDesc(perfilId).stream().map(AlertaEvento::from).toList();
    }

    @Transactional(readOnly = true)
    public AlertaEvento obter(UUID id) {
        return alertas.findById(id).map(AlertaEvento::from)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Alerta", id));
    }

    private AlertaEvento publicar(AlertaEmergencia alerta) {
        AlertaEvento evento = AlertaEvento.from(alerta);
        broker.convertAndSend(topico(alerta.getPerfil().getId()), evento);
        return evento;
    }
}
