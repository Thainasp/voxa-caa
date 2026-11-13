package br.edu.ifsp.voxa.repository;

import br.edu.ifsp.voxa.model.AlertaEmergencia;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface AlertaEmergenciaRepository extends JpaRepository<AlertaEmergencia, UUID> {
    List<AlertaEmergencia> findTop50ByPerfilIdOrderByCriadoEmDesc(UUID perfilId);
}
