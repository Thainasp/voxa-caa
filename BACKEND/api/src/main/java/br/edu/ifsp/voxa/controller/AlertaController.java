package br.edu.ifsp.voxa.controller;

import br.edu.ifsp.voxa.dto.AlertaDtos.AlertaEvento;
import br.edu.ifsp.voxa.service.AlertaService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/alertas")
@Tag(name = "Alertas", description = "Histórico do botão de emergência (enviado via WebSocket /app/alerta)")
public class AlertaController {

    private final AlertaService service;

    public AlertaController(AlertaService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "Últimos 50 alertas de um perfil")
    public List<AlertaEvento> historico(@RequestParam UUID perfilId) {
        return service.historico(perfilId);
    }

    @GetMapping("/{id}")
    public AlertaEvento obter(@PathVariable UUID id) {
        return service.obter(id);
    }
}
