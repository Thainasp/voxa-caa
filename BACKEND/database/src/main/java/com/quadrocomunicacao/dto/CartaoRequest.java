package com.quadrocomunicacao.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CartaoRequest(
        @NotBlank String texto,
        String caminhoImagem,
        String caminhoAudio,
        Boolean isFavorito,
        @Min(0) Integer frequenciaUso,
        @NotNull Long categoriaId,
        @NotNull Long pranchaId
) {}
