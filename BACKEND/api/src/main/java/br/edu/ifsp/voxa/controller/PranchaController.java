package br.edu.ifsp.voxa.controller;

import br.edu.ifsp.voxa.dto.PranchaDtos.PranchaCartaoRequest;
import br.edu.ifsp.voxa.dto.PranchaDtos.PranchaCartaoResponse;
import br.edu.ifsp.voxa.dto.PranchaDtos.PranchaRequest;
import br.edu.ifsp.voxa.dto.PranchaDtos.PranchaResponse;
import br.edu.ifsp.voxa.service.PranchaService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/pranchas")
@Tag(name = "Pranchas", description = "Entidade 3 – pranchas e relacionamento N:N com cartões")
public class PranchaController {

    private final PranchaService service;

    public PranchaController(PranchaService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<PranchaResponse> criar(@Valid @RequestBody PranchaRequest req) {
        PranchaResponse criada = service.criar(req);
        return ResponseEntity.created(ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}").buildAndExpand(criada.id()).toUri()).body(criada);
    }

    @GetMapping
    @Operation(summary = "Lista pranchas (filtro opcional por perfilId)")
    public List<PranchaResponse> listar(@RequestParam(required = false) UUID perfilId) {
        return service.listar(perfilId);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Busca a prancha com seus cartões em ordem")
    public PranchaResponse obter(@PathVariable UUID id) {
        return service.obter(id);
    }

    @PutMapping("/{id}")
    public PranchaResponse atualizar(@PathVariable UUID id, @Valid @RequestBody PranchaRequest req) {
        return service.atualizar(id, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void excluir(@PathVariable UUID id) {
        service.excluir(id);
    }

    @GetMapping("/{id}/cartoes")
    @Operation(summary = "N:N – cartões da prancha")
    public List<PranchaCartaoResponse> cartoes(@PathVariable UUID id) {
        return service.listarCartoes(id);
    }

    @PutMapping("/{id}/cartoes/{cartaoId}")
    @Operation(summary = "N:N – adiciona o cartão à prancha ou muda a ordem")
    public PranchaCartaoResponse vincular(@PathVariable UUID id, @PathVariable UUID cartaoId,
                                          @Valid @RequestBody PranchaCartaoRequest req) {
        return service.vincular(id, cartaoId, req.ordem());
    }

    @DeleteMapping("/{id}/cartoes/{cartaoId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "N:N – remove o cartão da prancha (o cartão continua existindo)")
    public void desvincular(@PathVariable UUID id, @PathVariable UUID cartaoId) {
        service.desvincular(id, cartaoId);
    }
}
