package com.quadrocomunicacao.controller;

import com.quadrocomunicacao.dto.PranchaRequest;
import com.quadrocomunicacao.model.Prancha;
import com.quadrocomunicacao.service.PranchaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/pranchas")
@RequiredArgsConstructor
public class PranchaController {

    private final PranchaService pranchaService;

    @PostMapping
    public ResponseEntity<Prancha> criar(@Valid @RequestBody PranchaRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(pranchaService.criar(request));
    }

    @GetMapping("/usuario/{usuarioId}")
    public ResponseEntity<List<Prancha>> listarPorUsuario(@PathVariable Long usuarioId) {
        return ResponseEntity.ok(pranchaService.listarPorUsuario(usuarioId));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(@PathVariable Long id) {
        pranchaService.excluir(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/compartilhar")
    public ResponseEntity<String> compartilhar(@PathVariable Long id) {
        return ResponseEntity.ok(pranchaService.compartilhar(id));
    }
}
