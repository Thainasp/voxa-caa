package br.edu.ifsp.voxa.model;

import jakarta.persistence.*;

/**
 * Relacionamento N:N Prancha x Cartao com atributo próprio (ordem).
 * Um cartão pode aparecer em várias pranchas e uma prancha tem vários cartões.
 */
@Entity
@Table(name = "prancha_cartao")
public class PranchaCartao {

    @EmbeddedId
    private PranchaCartaoId id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @MapsId("pranchaId")
    @JoinColumn(name = "prancha_id")
    private Prancha prancha;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @MapsId("cartaoId")
    @JoinColumn(name = "cartao_id")
    private Cartao cartao;

    private Integer ordem = 0;

    public PranchaCartao() {
    }

    public PranchaCartao(Prancha prancha, Cartao cartao, Integer ordem) {
        this.id = new PranchaCartaoId(prancha.getId(), cartao.getId());
        this.prancha = prancha;
        this.cartao = cartao;
        this.ordem = ordem;
    }

    public PranchaCartaoId getId() { return id; }
    public Prancha getPrancha() { return prancha; }
    public Cartao getCartao() { return cartao; }
    public Integer getOrdem() { return ordem; }
    public void setOrdem(Integer ordem) { this.ordem = ordem; }
}
