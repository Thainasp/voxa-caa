package com.quadrocomunicacao.repository;

import com.quadrocomunicacao.model.Cartao;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CartaoRepository extends JpaRepository<Cartao, Long> {

    List<Cartao> findByPranchaId(Long pranchaId);

    List<Cartao> findByCategoriaId(Long categoriaId);

    List<Cartao> findByPranchaIdAndIsFavoritoTrue(Long pranchaId);
}
