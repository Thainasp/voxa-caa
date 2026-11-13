package br.edu.ifsp.voxa.model;

import jakarta.persistence.*;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/** Entidade 3 — prancha (tábua) temática de comunicação. */
@Entity
@Table(name = "prancha")
public class Prancha {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "perfil_id", nullable = false)
    private Perfil perfil;

    @Column(nullable = false)
    private String chave;

    @Column(nullable = false)
    private String nome;

    private String icone;

    @Column(name = "imagem_url")
    private String imagemUrl;

    @Column(name = "caminho_audio")
    private String caminhoAudio;

    private Integer ordem = 0;

    @Column(name = "catalogo_arasaac", nullable = false)
    private Boolean catalogoArasaac = false;

    /** Lado "prancha" da relação N:N com Cartao (via PranchaCartao). */
    @OneToMany(mappedBy = "prancha", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("ordem ASC")
    private List<PranchaCartao> itens = new ArrayList<>();

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public Perfil getPerfil() { return perfil; }
    public void setPerfil(Perfil perfil) { this.perfil = perfil; }
    public String getChave() { return chave; }
    public void setChave(String chave) { this.chave = chave; }
    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }
    public String getIcone() { return icone; }
    public void setIcone(String icone) { this.icone = icone; }
    public String getImagemUrl() { return imagemUrl; }
    public void setImagemUrl(String imagemUrl) { this.imagemUrl = imagemUrl; }
    public String getCaminhoAudio() { return caminhoAudio; }
    public void setCaminhoAudio(String caminhoAudio) { this.caminhoAudio = caminhoAudio; }
    public Integer getOrdem() { return ordem; }
    public void setOrdem(Integer ordem) { this.ordem = ordem; }
    public Boolean getCatalogoArasaac() { return catalogoArasaac; }
    public void setCatalogoArasaac(Boolean catalogoArasaac) { this.catalogoArasaac = catalogoArasaac; }
    public List<PranchaCartao> getItens() { return itens; }
}
