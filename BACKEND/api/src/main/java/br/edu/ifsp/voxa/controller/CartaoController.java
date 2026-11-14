package br.edu.ifsp.voxa.controller;

import br.edu.ifsp.voxa.dto.CartaoDtos.CartaoRequest;
import br.edu.ifsp.voxa.dto.CartaoDtos.CartaoResponse;
import br.edu.ifsp.voxa.service.CartaoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/cartoes")
@Tag(name = "Cartões", description = "Entidade 4 – cartões de comunicação")
public class CartaoController {

    private final CartaoService service;

    public CartaoController(CartaoService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<CartaoResponse> criar(@Valid @RequestBody CartaoRequest req,
                                                @AuthenticationPrincipal Jwt jwt) {
        CartaoResponse criado = service.criar(req, usuarioId(jwt));
        return ResponseEntity.created(ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}").buildAndExpand(criado.id()).toUri()).body(criado);
    }

    @GetMapping
    @Operation(summary = "Lista cartões (filtros opcionais: perfilId e busca por texto)")
    public List<CartaoResponse> listar(@RequestParam(required = false) UUID perfilId,
                                       @RequestParam(required = false) String busca,
                                       @AuthenticationPrincipal Jwt jwt) {
        return service.listar(perfilId, busca, usuarioId(jwt));
    }

    @GetMapping("/{id}")
    public CartaoResponse obter(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt) {
        return service.obter(id, usuarioId(jwt));
    }

    @PutMapping("/{id}")
    public CartaoResponse atualizar(@PathVariable UUID id, @Valid @RequestBody CartaoRequest req,
                                    @AuthenticationPrincipal Jwt jwt) {
        return service.salvar(id, req, usuarioId(jwt));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void excluir(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt) {
        service.excluir(id, usuarioId(jwt));
    }

    @GetMapping("/{id}/pranchas")
    public List<UUID> pranchas(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt) {
        return service.listarPranchas(id, usuarioId(jwt));
    }

    private UUID usuarioId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
