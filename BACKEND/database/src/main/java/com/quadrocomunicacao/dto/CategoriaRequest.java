package com.quadrocomunicacao.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CategoriaRequest(
        @NotBlank String nome,
        @NotNull Boolean isControleParental
) {}
