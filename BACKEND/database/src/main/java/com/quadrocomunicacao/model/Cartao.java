package com.quadrocomunicacao.model;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
        name = "cartao",
        indexes = {
                @Index(name = "idx_cartao_categoria_id", columnList = "categoria_id"),
                @Index(name = "idx_cartao_prancha_id", columnList = "prancha_id"),
                @Index(name = "idx_cartao_favorito", columnList = "is_favorito")
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
public class Cartao {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    @NotBlank
    @Size(max = 255)
    @Column(name = "texto", nullable = false, length = 255)
    private String texto;

    @Size(max = 500)
    @Column(name = "caminho_imagem", length = 500)
    private String caminhoImagem;

    @Size(max = 500)
    @Column(name = "caminho_audio", length = 500)
    private String caminhoAudio;

    @NotNull
    @Column(name = "is_favorito", nullable = false)
    @Builder.Default
    private Boolean isFavorito = false;

    @NotNull
    @Min(0)
    @Column(name = "frequencia_uso", nullable = false)
    @Builder.Default
    private Integer frequenciaUso = 0;

    // Lado "muitos" do relacionamento Categoria (1) -> Cartao (*)
    @NotNull
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(
            name = "categoria_id",
            nullable = false,
            foreignKey = @ForeignKey(name = "fk_cartao_categoria")
    )
    @JsonBackReference
    private Categoria categoria;

    // Lado "muitos" do relacionamento Prancha (1) -> Cartao (*)
    @NotNull
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(
            name = "prancha_id",
            nullable = false,
            foreignKey = @ForeignKey(name = "fk_cartao_prancha")
    )
    @JsonBackReference
    private Prancha prancha;
}
