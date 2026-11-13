package br.edu.ifsp.voxa.model;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

/** Chave composta da tabela associativa prancha_cartao. */
@Embeddable
public class PranchaCartaoId implements Serializable {

    @Column(name = "prancha_id")
    private UUID pranchaId;

    @Column(name = "cartao_id")
    private UUID cartaoId;

    public PranchaCartaoId() {
    }

    public PranchaCartaoId(UUID pranchaId, UUID cartaoId) {
        this.pranchaId = pranchaId;
        this.cartaoId = cartaoId;
    }

    public UUID getPranchaId() { return pranchaId; }
    public UUID getCartaoId() { return cartaoId; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof PranchaCartaoId other)) return false;
        return Objects.equals(pranchaId, other.pranchaId) && Objects.equals(cartaoId, other.cartaoId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(pranchaId, cartaoId);
    }
}
