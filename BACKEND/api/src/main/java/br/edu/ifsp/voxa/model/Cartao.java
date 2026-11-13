package br.edu.ifsp.voxa.model;

import jakarta.persistence.*;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/** Entidade 4 — cartão de comunicação (pictograma + texto + cor Fitzgerald). */
@Entity
@Table(name = "cartao")
public class Cartao {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "perfil_id", nullable = false)
    private Perfil perfil;

    @Column(nullable = false)
    private String texto;

    @Column(name = "caminho_imagem")
    private String caminhoImagem;

    @Column(name = "caminho_audio")
    private String caminhoAudio;

    private String icone;

    @Column(name = "cor_hex")
    private String corHex;

    @Column(name = "arasaac_id")
    private String arasaacId;

    @Column(name = "is_favorito")
    private Boolean favorito = false;

    @Column(name = "frequencia_uso")
    private Integer frequenciaUso = 0;

    /** Lado "cartão" da relação N:N com Prancha. */
    @OneToMany(mappedBy = "cartao", cascade = CascadeType.REMOVE)
    private List<PranchaCartao> pranchas = new ArrayList<>();

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public Perfil getPerfil() { return perfil; }
    public void setPerfil(Perfil perfil) { this.perfil = perfil; }
    public String getTexto() { return texto; }
    public void setTexto(String texto) { this.texto = texto; }
    public String getCaminhoImagem() { return caminhoImagem; }
    public void setCaminhoImagem(String caminhoImagem) { this.caminhoImagem = caminhoImagem; }
    public String getCaminhoAudio() { return caminhoAudio; }
    public void setCaminhoAudio(String caminhoAudio) { this.caminhoAudio = caminhoAudio; }
    public String getIcone() { return icone; }
    public void setIcone(String icone) { this.icone = icone; }
    public String getCorHex() { return corHex; }
    public void setCorHex(String corHex) { this.corHex = corHex; }
    public String getArasaacId() { return arasaacId; }
    public void setArasaacId(String arasaacId) { this.arasaacId = arasaacId; }
    public Boolean getFavorito() { return favorito; }
    public void setFavorito(Boolean favorito) { this.favorito = favorito; }
    public Integer getFrequenciaUso() { return frequenciaUso; }
    public void setFrequenciaUso(Integer frequenciaUso) { this.frequenciaUso = frequenciaUso; }
    public List<PranchaCartao> getPranchas() { return pranchas; }
}
