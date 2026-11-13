package br.edu.ifsp.voxa.controller;

import br.edu.ifsp.voxa.dto.CartaoDtos.CartaoRequest;
import br.edu.ifsp.voxa.dto.CartaoDtos.CartaoResponse;
import br.edu.ifsp.voxa.service.CartaoService;
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
@RequestMapping("/api/v1/cartoes")
@Tag(name = "Cartões", description = "Entidade 4 – cartões de comunicação")
public class CartaoController {

    private final CartaoService service;

    public CartaoController(CartaoService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<CartaoResponse> criar(@Valid @RequestBody CartaoRequest req) {
        CartaoResponse criado = service.criar(req);
        return ResponseEntity.created(ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}").buildAndExpand(criado.id()).toUri()).body(criado);
    }

    @GetMapping
    @Operation(summary = "Lista cartões (filtros opcionais: perfilId e busca por texto)")
    public List<CartaoResponse> listar(@RequestParam(required = false) UUID perfilId,
                                       @RequestParam(required = false) String busca) {
        return service.listar(perfilId, busca);
    }

    @GetMapping("/{id}")
    public CartaoResponse obter(@PathVariable UUID id) {
        return service.obter(id);
    }

    @PutMapping("/{id}")
    public CartaoResponse atualizar(@PathVariable UUID id, @Valid @RequestBody CartaoRequest req) {
        return service.atualizar(id, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void excluir(@PathVariable UUID id) {
        service.excluir(id);
    }
}
