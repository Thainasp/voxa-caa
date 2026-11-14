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
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
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

    private static final Logger log = LoggerFactory.getLogger(AlertaService.class);
    private static final String TELEFONE_DEMO_PADRAO = "(11) 99999-0000";

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
        Perfil perfil;
        try {
            perfil = perfilService.buscar(msg.perfilId());
        } catch (RecursoNaoEncontradoException e) {
            if (msg.clienteId() != null && msg.perfilNome() != null && !msg.perfilNome().isBlank()) {
                log.info("Processando alerta WebSocket do perfil Supabase {} ({}) em modo demonstracao",
                        msg.perfilNome(), msg.perfilId());
                return processarAlertaExternoSupabase(msg);
            }
            throw e;
        }

        Usuario usuario = perfil.getUsuario();
        if (!usuario.getId().equals(msg.usuarioId())) {
            throw new RegraNegocioException("O perfil não pertence ao usuário informado");
        }

        String telefone = (usuario.getTelefone() != null && !usuario.getTelefone().isBlank())
                ? usuario.getTelefone()
                : TELEFONE_DEMO_PADRAO;

        AlertaEmergencia alerta = new AlertaEmergencia();
        alerta.setClienteId(msg.clienteId());
        alerta.setUsuario(usuario);
        alerta.setPerfil(perfil);
        alerta.setMensagem(msg.mensagem() == null || msg.mensagem().isBlank()
                ? "ALERTA VOXA: " + perfil.getNome() + " acionou o botão de emergência e precisa de ajuda."
                : msg.mensagem());
        alerta.setTelefoneDestino(telefone);
        alertas.save(alerta);
        publicar(alerta);

        boolean enviado = sms.enviar(telefone, alerta.getMensagem());
        alerta.setStatus(enviado ? StatusAlerta.SMS_ENVIADO : StatusAlerta.SMS_FALHOU);
        return publicar(alerta);
    }

    private AlertaEvento processarAlertaExternoSupabase(AlertaMensagem msg) {
        UUID alertaId = UUID.randomUUID();
        OffsetDateTime agora = OffsetDateTime.now();
        String texto = (msg.mensagem() == null || msg.mensagem().isBlank())
                ? "ALERTA VOXA: " + msg.perfilNome() + " acionou o botão de emergência e precisa de ajuda."
                : msg.mensagem();
        String telefoneMascarado = "*****0000";

        AlertaEvento recebido = new AlertaEvento(
                alertaId,
                msg.clienteId(),
                msg.perfilId(),
                msg.perfilNome(),
                texto,
                StatusAlerta.RECEBIDO,
                telefoneMascarado,
                agora);
        broker.convertAndSend(topico(msg.perfilId()), recebido);

        boolean enviado = sms.enviar(TELEFONE_DEMO_PADRAO, texto);
        AlertaEvento resultado = new AlertaEvento(
                alertaId,
                msg.clienteId(),
                msg.perfilId(),
                msg.perfilNome(),
                texto,
                enviado ? StatusAlerta.SMS_ENVIADO : StatusAlerta.SMS_FALHOU,
                telefoneMascarado,
                agora);
        broker.convertAndSend(topico(msg.perfilId()), resultado);
        return resultado;
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