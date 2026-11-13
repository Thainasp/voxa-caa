package br.edu.ifsp.voxa.dto;

import br.edu.ifsp.voxa.model.AlertaEmergencia;
import br.edu.ifsp.voxa.model.StatusAlerta;
import jakarta.validation.constraints.NotNull;

import java.time.OffsetDateTime;
import java.util.UUID;

public final class AlertaDtos {

    private AlertaDtos() {
    }

    /** Mensagem STOMP recebida em /app/alerta (enviada pelo app ou pelo cliente web). */
    public record AlertaMensagem(
            UUID clienteId,
            @NotNull UUID usuarioId,
            @NotNull UUID perfilId,
            String perfilNome,
            String mensagem,
            String enviadoEm) {
    }

    /** Evento publicado em /topic/alertas/{perfilId}. */
    public record AlertaEvento(
            UUID alertaId,
            UUID clienteId,
            UUID perfilId,
            String perfilNome,
            String mensagem,
            StatusAlerta status,
            String telefoneMascarado,
            OffsetDateTime criadoEm) {

        public static AlertaEvento from(AlertaEmergencia a) {
            return new AlertaEvento(a.getId(), a.getClienteId(), a.getPerfil().getId(), a.getPerfil().getNome(),
                    a.getMensagem(), a.getStatus(), mascarar(a.getTelefoneDestino()), a.getCriadoEm());
        }

        /** LGPD (RN-04): o telefone completo não é publicado no tópico. */
        static String mascarar(String telefone) {
            if (telefone == null || telefone.length() < 4) return null;
            String digitos = telefone.replaceAll("\\D", "");
            if (digitos.length() < 4) return null;
            return "*****" + digitos.substring(digitos.length() - 4);
        }
    }
}
