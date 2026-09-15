package com.quadrocomunicacao.service;

import com.quadrocomunicacao.dto.CartaoRequest;
import com.quadrocomunicacao.model.Cartao;
import com.quadrocomunicacao.model.Categoria;
import com.quadrocomunicacao.model.Prancha;
import com.quadrocomunicacao.repository.CartaoRepository;
import com.quadrocomunicacao.repository.CategoriaRepository;
import com.quadrocomunicacao.repository.PranchaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CartaoService {

    private final CartaoRepository cartaoRepository;
    private final CategoriaRepository categoriaRepository;
    private final PranchaRepository pranchaRepository;

    @Transactional
    public Cartao adicionar(CartaoRequest request) {
        Categoria categoria = categoriaRepository.findById(request.categoriaId())
                .orElseThrow(() -> new IllegalArgumentException("Categoria nao encontrada: " + request.categoriaId()));
        Prancha prancha = pranchaRepository.findById(request.pranchaId())
                .orElseThrow(() -> new IllegalArgumentException("Prancha nao encontrada: " + request.pranchaId()));

        Cartao cartao = Cartao.builder()
                .texto(request.texto())
                .caminhoImagem(request.caminhoImagem())
                .caminhoAudio(request.caminhoAudio())
                .isFavorito(request.isFavorito() != null ? request.isFavorito() : false)
                .frequenciaUso(request.frequenciaUso() != null ? request.frequenciaUso() : 0)
                .categoria(categoria)
                .prancha(prancha)
                .build();

        return cartaoRepository.save(cartao);
    }

    @Transactional
    public Cartao editar(Long id, CartaoRequest request) {
        Cartao cartao = cartaoRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Cartao nao encontrado: " + id));

        if (!cartao.getCategoria().getId().equals(request.categoriaId())) {
            Categoria categoria = categoriaRepository.findById(request.categoriaId())
                    .orElseThrow(() -> new IllegalArgumentException("Categoria nao encontrada: " + request.categoriaId()));
            cartao.setCategoria(categoria);
        }
        if (!cartao.getPrancha().getId().equals(request.pranchaId())) {
            Prancha prancha = pranchaRepository.findById(request.pranchaId())
                    .orElseThrow(() -> new IllegalArgumentException("Prancha nao encontrada: " + request.pranchaId()));
            cartao.setPrancha(prancha);
        }

        cartao.setTexto(request.texto());
        cartao.setCaminhoImagem(request.caminhoImagem());
        cartao.setCaminhoAudio(request.caminhoAudio());
        if (request.isFavorito() != null) {
            cartao.setIsFavorito(request.isFavorito());
        }
        if (request.frequenciaUso() != null) {
            cartao.setFrequenciaUso(request.frequenciaUso());
        }

        return cartaoRepository.save(cartao);
    }

    @Transactional
    public void excluir(Long id) {
        cartaoRepository.deleteById(id);
    }

    public List<Cartao> listarPorPrancha(Long pranchaId) {
        return cartaoRepository.findByPranchaId(pranchaId);
    }

    @Transactional
    public String reproduzirAudio(Long id) {
        Cartao cartao = cartaoRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Cartao nao encontrado: " + id));

        cartao.setFrequenciaUso(cartao.getFrequenciaUso() + 1);
        cartaoRepository.save(cartao);

        return cartao.getCaminhoAudio();
    }
}
