package br.edu.ifsp.voxa.websocket;

import br.edu.ifsp.voxa.dto.AlertaDtos.AlertaMensagem;
import br.edu.ifsp.voxa.service.AlertaService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.handler.annotation.MessageExceptionHandler;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.annotation.SendToUser;
import org.springframework.stereotype.Controller;

import java.util.Map;

@Controller
public class AlertaWebSocketController {

    private static final Logger log = LoggerFactory.getLogger(AlertaWebSocketController.class);

    private final AlertaService alertaService;

    public AlertaWebSocketController(AlertaService alertaService) {
        this.alertaService = alertaService;
    }

    /** SEND /app/alerta  ->  eventos em /topic/alertas/{perfilId}. */
    @MessageMapping("/alerta")
    public void receberAlerta(@Valid @Payload AlertaMensagem mensagem) {
        alertaService.processar(mensagem);
    }

    /** Erros de validação/negócio voltam só para quem enviou. */
    @MessageExceptionHandler
    @SendToUser("/queue/erros")
    public Map<String, String> erro(Exception e) {
        log.warn("Alerta rejeitado: {}", e.getMessage());
        return Map.of("erro", e.getMessage() == null ? "Erro ao processar alerta" : e.getMessage());
    }
}
