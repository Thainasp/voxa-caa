package br.edu.ifsp.voxa.repository;

import br.edu.ifsp.voxa.model.Cartao;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface CartaoRepository extends JpaRepository<Cartao, UUID> {
    List<Cartao> findByPerfilIdOrderByTextoAsc(UUID perfilId);
    List<Cartao> findByPerfilIdAndTextoContainingIgnoreCaseOrderByTextoAsc(UUID perfilId, String texto);
}
