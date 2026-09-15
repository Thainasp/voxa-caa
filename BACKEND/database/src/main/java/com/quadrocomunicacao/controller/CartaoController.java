package com.quadrocomunicacao.controller;

import com.quadrocomunicacao.dto.CartaoRequest;
import com.quadrocomunicacao.model.Cartao;
import com.quadrocomunicacao.service.CartaoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/cartoes")
@RequiredArgsConstructor
public class CartaoController {

    private final CartaoService cartaoService;

    @PostMapping
    public ResponseEntity<Cartao> adicionar(@Valid @RequestBody CartaoRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(cartaoService.adicionar(request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Cartao> editar(@PathVariable Long id, @Valid @RequestBody CartaoRequest request) {
        return ResponseEntity.ok(cartaoService.editar(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(@PathVariable Long id) {
        cartaoService.excluir(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/prancha/{pranchaId}")
    public ResponseEntity<List<Cartao>> listarPorPrancha(@PathVariable Long pranchaId) {
        return ResponseEntity.ok(cartaoService.listarPorPrancha(pranchaId));
    }

    @PostMapping("/{id}/reproduzir")
    public ResponseEntity<Map<String, String>> reproduzirAudio(@PathVariable Long id) {
        String caminhoAudio = cartaoService.reproduzirAudio(id);
        return ResponseEntity.ok(Map.of("caminhoAudio", caminhoAudio));
    }
}
