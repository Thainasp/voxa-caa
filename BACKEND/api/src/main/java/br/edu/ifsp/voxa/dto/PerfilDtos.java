package br.edu.ifsp.voxa.dto;

import br.edu.ifsp.voxa.model.Perfil;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public final class PerfilDtos {

    private PerfilDtos() {
    }

    public record PerfilRequest(
            @NotNull UUID usuarioId,
            @NotBlank @Size(max = 80) String nome,
            String avatarUrl,
            Boolean responsavel) {
    }

    public record PerfilUpdateRequest(
            @NotBlank @Size(max = 80) String nome,
            String avatarUrl) {
    }

    public record PerfilResponse(
            UUID id,
            UUID usuarioId,
            String nome,
            String avatarUrl,
            boolean responsavel) {

        public static PerfilResponse from(Perfil p) {
            return new PerfilResponse(p.getId(), p.getUsuario().getId(), p.getNome(),
                    p.getAvatarUrl(), Boolean.TRUE.equals(p.getResponsavel()));
        }
    }
}
