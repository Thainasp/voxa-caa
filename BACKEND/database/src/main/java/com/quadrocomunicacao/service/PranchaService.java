package com.quadrocomunicacao.service;

import com.quadrocomunicacao.dto.PranchaRequest;
import com.quadrocomunicacao.model.Prancha;
import com.quadrocomunicacao.model.Usuario;
import com.quadrocomunicacao.repository.PranchaRepository;
import com.quadrocomunicacao.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Base64;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PranchaService {

    private final PranchaRepository pranchaRepository;
    private final UsuarioRepository usuarioRepository;

    @Transactional
    public Prancha criar(PranchaRequest request) {
        Usuario usuario = usuarioRepository.findById(request.usuarioId())
                .orElseThrow(() -> new IllegalArgumentException("Usuario nao encontrado: " + request.usuarioId()));

        Prancha prancha = Prancha.builder()
                .nome(request.nome())
                .usuario(usuario)
                .build();

        return pranchaRepository.save(prancha);
    }

    public List<Prancha> listarPorUsuario(Long usuarioId) {
        return pranchaRepository.findByUsuarioId(usuarioId);
    }

    @Transactional
    public void excluir(Long id) {
        // fk_cartao_prancha esta ON DELETE CASCADE: excluir a prancha
        // tambem remove os cartoes que pertencem a ela.
        pranchaRepository.deleteById(id);
    }

    // adicionarCartao()/excluirCartao() do diagrama sao cobertos por CartaoService,
    // ja que um Cartao referencia sua Prancha atraves do campo pranchaId.

    public String compartilhar(Long id) {
        pranchaRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Prancha nao encontrada: " + id));

        String token = Base64.getUrlEncoder().withoutPadding()
                .encodeToString(UUID.randomUUID().toString().getBytes());

        // Em um cenario real esse token seria persistido (com expiracao/permissoes)
        // em uma tabela propria de compartilhamento.
        return "/pranchas/compartilhadas/" + id + "?token=" + token;
    }
}
