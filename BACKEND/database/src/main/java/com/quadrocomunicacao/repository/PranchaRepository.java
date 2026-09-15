package com.quadrocomunicacao.repository;

import com.quadrocomunicacao.model.Prancha;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PranchaRepository extends JpaRepository<Prancha, Long> {

    List<Prancha> findByUsuarioId(Long usuarioId);
}
