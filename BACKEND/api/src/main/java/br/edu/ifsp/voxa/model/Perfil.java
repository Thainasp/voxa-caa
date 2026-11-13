package br.edu.ifsp.voxa.model;

import jakarta.persistence.*;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/** Entidade 2 — perfil de uso (titular ou dependente) dentro de uma conta. */
@Entity
@Table(name = "perfil")
public class Perfil {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Lado N do relacionamento Usuario 1:N Perfil. */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    @Column(nullable = false)
    private String nome;

    @Column(name = "avatar_url")
    private String avatarUrl;

    @Column(name = "is_responsavel", nullable = false)
    private Boolean responsavel = false;

    /** Relacionamento 1:N — um perfil possui várias pranchas. */
    @OneToMany(mappedBy = "perfil", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("ordem ASC")
    private List<Prancha> pranchas = new ArrayList<>();

    /** Relacionamento 1:N — um perfil possui vários cartões. */
    @OneToMany(mappedBy = "perfil", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Cartao> cartoes = new ArrayList<>();

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public Usuario getUsuario() { return usuario; }
    public void setUsuario(Usuario usuario) { this.usuario = usuario; }
    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }
    public String getAvatarUrl() { return avatarUrl; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }
    public Boolean getResponsavel() { return responsavel; }
    public void setResponsavel(Boolean responsavel) { this.responsavel = responsavel; }
    public List<Prancha> getPranchas() { return pranchas; }
    public List<Cartao> getCartoes() { return cartoes; }
}
