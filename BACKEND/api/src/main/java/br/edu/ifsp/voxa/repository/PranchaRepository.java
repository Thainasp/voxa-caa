package br.edu.ifsp.voxa.repository;

import br.edu.ifsp.voxa.model.Prancha;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PranchaRepository extends JpaRepository<Prancha, UUID> {
    List<Prancha> findByPerfilIdOrderByOrdemAsc(UUID perfilId);
    List<Prancha> findByPerfilUsuarioIdOrderByOrdemAsc(UUID usuarioId);
    List<Prancha> findByPerfilIdAndCatalogoArasaacFalseOrderByOrdemAsc(UUID perfilId);
    List<Prancha> findByPerfilUsuarioIdAndCatalogoArasaacFalseOrderByOrdemAsc(UUID usuarioId);
    boolean existsByPerfilIdAndChave(UUID perfilId, String chave);
    boolean existsByPerfilIdAndChaveAndIdNot(UUID perfilId, String chave, UUID id);
    Optional<Prancha> findByIdAndPerfilUsuarioId(UUID id, UUID usuarioId);
}
