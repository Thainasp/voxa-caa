package br.edu.ifsp.voxa.repository;

import br.edu.ifsp.voxa.model.PranchaCartao;
import br.edu.ifsp.voxa.model.PranchaCartaoId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface PranchaCartaoRepository extends JpaRepository<PranchaCartao, PranchaCartaoId> {
    List<PranchaCartao> findByPranchaIdOrderByOrdemAsc(UUID pranchaId);
}
