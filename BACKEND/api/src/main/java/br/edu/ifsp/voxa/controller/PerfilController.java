package br.edu.ifsp.voxa.controller;

import br.edu.ifsp.voxa.exception.RecursoNaoEncontradoException;
import br.edu.ifsp.voxa.dto.PerfilDtos.PerfilRequest;
import br.edu.ifsp.voxa.dto.PerfilDtos.PerfilResponse;
import br.edu.ifsp.voxa.dto.PerfilDtos.PerfilUpdateRequest;
import br.edu.ifsp.voxa.service.PerfilService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.server.ResponseStatusException;
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
    public ResponseEntity<PerfilResponse> criar(
            @AuthenticationPrincipal Jwt principal,
            @Valid @RequestBody PerfilRequest req) {
        UUID userId = userId(principal);
        requireOwnUser(req.usuarioId(), userId);
        PerfilResponse criado = service.criar(req);
        return ResponseEntity.created(ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}").buildAndExpand(criado.id()).toUri()).body(criado);
    }

    @GetMapping
    @Operation(summary = "Lista perfis (filtro opcional por usuarioId)")
    public List<PerfilResponse> listar(
            @RequestParam(required = false) UUID usuarioId,
            @AuthenticationPrincipal Jwt principal) {
        UUID authenticatedUserId = userId(principal);
        if (usuarioId != null) {
            requireOwnUser(usuarioId, authenticatedUserId);
        }
        return service.listar(authenticatedUserId);
    }

    @GetMapping("/{id}")
    public PerfilResponse obter(@PathVariable UUID id, @AuthenticationPrincipal Jwt principal) {
        return service.obter(id, userId(principal));
    }

    @PutMapping("/{id}")
    public PerfilResponse atualizar(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt principal,
            @Valid @RequestBody PerfilUpdateRequest req) {
        return service.atualizar(id, userId(principal), req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Exclui um dependente (409 se for o responsável)")
    public void excluir(@PathVariable UUID id, @AuthenticationPrincipal Jwt principal) {
        service.excluir(id, userId(principal));
    }

    private static UUID userId(Jwt principal) {
        String subject = principal.getSubject();
        if (subject == null || subject.isBlank()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Token sem identificador de usuário.");
        }
        try {
            return UUID.fromString(subject);
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Identificador de usuário inválido.");
        }
    }

    private static void requireOwnUser(UUID requestedId, UUID authenticatedUserId) {
        if (!requestedId.equals(authenticatedUserId)) {
            throw new RecursoNaoEncontradoException("Usuário", requestedId);
        }
    }
}
