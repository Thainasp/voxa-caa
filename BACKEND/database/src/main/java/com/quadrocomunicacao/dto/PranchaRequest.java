package com.quadrocomunicacao.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record PranchaRequest(
        @NotBlank String nome,
        @NotNull Long usuarioId
) {}
