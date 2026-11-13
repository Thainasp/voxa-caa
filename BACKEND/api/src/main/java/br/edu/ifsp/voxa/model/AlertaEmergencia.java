package br.edu.ifsp.voxa.model;

import jakarta.persistence.*;

import java.time.OffsetDateTime;
import java.util.UUID;

/** Histórico do botão de emergência (WebSocket/STOMP). */
@Entity
@Table(name = "alerta_emergencia")
public class AlertaEmergencia {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Id gerado pelo app para casar a resposta com o envio. */
    @Column(name = "cliente_id")
    private UUID clienteId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "perfil_id", nullable = false)
    private Perfil perfil;

    @Column(nullable = false)
    private String mensagem;

    @Column(name = "telefone_destino")
    private String telefoneDestino;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StatusAlerta status = StatusAlerta.RECEBIDO;

    @Column(name = "criado_em", nullable = false)
    private OffsetDateTime criadoEm = OffsetDateTime.now();

    public UUID getId() { return id; }
    public UUID getClienteId() { return clienteId; }
    public void setClienteId(UUID clienteId) { this.clienteId = clienteId; }
    public Usuario getUsuario() { return usuario; }
    public void setUsuario(Usuario usuario) { this.usuario = usuario; }
    public Perfil getPerfil() { return perfil; }
    public void setPerfil(Perfil perfil) { this.perfil = perfil; }
    public String getMensagem() { return mensagem; }
    public void setMensagem(String mensagem) { this.mensagem = mensagem; }
    public String getTelefoneDestino() { return telefoneDestino; }
    public void setTelefoneDestino(String telefoneDestino) { this.telefoneDestino = telefoneDestino; }
    public StatusAlerta getStatus() { return status; }
    public void setStatus(StatusAlerta status) { this.status = status; }
    public OffsetDateTime getCriadoEm() { return criadoEm; }
}
