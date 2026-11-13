package br.edu.ifsp.voxa.repository;

import br.edu.ifsp.voxa.model.Perfil;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface PerfilRepository extends JpaRepository<Perfil, UUID> {
    List<Perfil> findByUsuarioIdOrderByNomeAsc(UUID usuarioId);
    boolean existsByUsuarioIdAndResponsavelTrue(UUID usuarioId);
}
