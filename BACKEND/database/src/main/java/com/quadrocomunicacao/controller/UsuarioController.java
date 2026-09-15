package com.quadrocomunicacao.controller;

import com.quadrocomunicacao.dto.LoginRequest;
import com.quadrocomunicacao.dto.UsuarioRequest;
import com.quadrocomunicacao.model.Usuario;
import com.quadrocomunicacao.service.UsuarioService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/usuarios")
@RequiredArgsConstructor
public class UsuarioController {

    private final UsuarioService usuarioService;

    @PostMapping
    public ResponseEntity<Usuario> cadastrar(@Valid @RequestBody UsuarioRequest request) {
        Usuario usuario = usuarioService.cadastrar(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(usuario);
    }

    @PostMapping("/login")
    public ResponseEntity<Usuario> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(usuarioService.login(request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Usuario> gerenciarPerfil(@PathVariable Long id,
                                                    @Valid @RequestBody UsuarioRequest request) {
        return ResponseEntity.ok(usuarioService.gerenciarPerfil(id, request));
    }
}
