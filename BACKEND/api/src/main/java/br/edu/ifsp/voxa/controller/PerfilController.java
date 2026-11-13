package br.edu.ifsp.voxa.controller;

import br.edu.ifsp.voxa.dto.PerfilDtos.PerfilRequest;
import br.edu.ifsp.voxa.dto.PerfilDtos.PerfilResponse;
import br.edu.ifsp.voxa.dto.PerfilDtos.PerfilUpdateRequest;
import br.edu.ifsp.voxa.service.PerfilService;
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
@RequestMapping("/api/v1/perfis")
@Tag(name = "Perfis", description = "Entidade 2 – perfis (titular e dependentes)")
public class PerfilController {

    private final PerfilService service;

    public PerfilController(PerfilService service) {
        this.service = service;
    }

    @PostMapping
    @Operation(summary = "Cria um perfil dependente na conta")
    public ResponseEntity<PerfilResponse> criar(@Valid @RequestBody PerfilRequest req) {
        PerfilResponse criado = service.criar(req);
        return ResponseEntity.created(ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}").buildAndExpand(criado.id()).toUri()).body(criado);
    }

    @GetMapping
    @Operation(summary = "Lista perfis (filtro opcional por usuarioId)")
    public List<PerfilResponse> listar(@RequestParam(required = false) UUID usuarioId) {
        return service.listar(usuarioId);
    }

    @GetMapping("/{id}")
    public PerfilResponse obter(@PathVariable UUID id) {
        return service.obter(id);
    }

    @PutMapping("/{id}")
    public PerfilResponse atualizar(@PathVariable UUID id, @Valid @RequestBody PerfilUpdateRequest req) {
        return service.atualizar(id, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Exclui um dependente (409 se for o responsável)")
    public void excluir(@PathVariable UUID id) {
        service.excluir(id);
    }
}
