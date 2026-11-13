package br.edu.ifsp.voxa.controller;

import br.edu.ifsp.voxa.dto.PerfilDtos.PerfilResponse;
import br.edu.ifsp.voxa.dto.UsuarioDtos.UsuarioRequest;
import br.edu.ifsp.voxa.dto.UsuarioDtos.UsuarioResponse;
import br.edu.ifsp.voxa.service.UsuarioService;
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
@RequestMapping("/api/v1/usuarios")
@Tag(name = "Usuários", description = "Entidade 1 – conta do responsável")
public class UsuarioController {

    private final UsuarioService service;

    public UsuarioController(UsuarioService service) {
        this.service = service;
    }

    @PostMapping
    @Operation(summary = "Cria a conta e o perfil responsável")
    public ResponseEntity<UsuarioResponse> criar(@Valid @RequestBody UsuarioRequest req) {
        UsuarioResponse criado = service.criar(req);
        return ResponseEntity.created(ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}").buildAndExpand(criado.id()).toUri()).body(criado);
    }

    @GetMapping
    @Operation(summary = "Lista usuários")
    public List<UsuarioResponse> listar() {
        return service.listar();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Busca um usuário")
    public UsuarioResponse obter(@PathVariable UUID id) {
        return service.obter(id);
    }

    @GetMapping("/{id}/perfis")
    @Operation(summary = "Relacionamento 1:N – perfis do usuário")
    public List<PerfilResponse> perfis(@PathVariable UUID id) {
        return service.listarPerfis(id);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Atualiza um usuário")
    public UsuarioResponse atualizar(@PathVariable UUID id, @Valid @RequestBody UsuarioRequest req) {
        return service.atualizar(id, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Exclui o usuário e todos os perfis, pranchas e cartões (cascata)")
    public void excluir(@PathVariable UUID id) {
        service.excluir(id);
    }
}
