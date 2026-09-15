package com.quadrocomunicacao.service;

import com.quadrocomunicacao.dto.CategoriaRequest;
import com.quadrocomunicacao.model.Categoria;
import com.quadrocomunicacao.repository.CategoriaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CategoriaService {

    private final CategoriaRepository categoriaRepository;

    @Transactional
    public Categoria criar(CategoriaRequest request) {
        Categoria categoria = Categoria.builder()
                .nome(request.nome())
                .isControleParental(request.isControleParental())
                .build();

        return categoriaRepository.save(categoria);
    }

    public List<Categoria> listar() {
        return categoriaRepository.findAll();
    }

    public Categoria buscarPorId(Long id) {
        return categoriaRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Categoria nao encontrada: " + id));
    }

    @Transactional
    public void excluir(Long id) {
        // fk_cartao_categoria esta ON DELETE RESTRICT: o banco impede a exclusao
        // de uma categoria que ainda possua cartoes vinculados.
        categoriaRepository.deleteById(id);
    }
}
