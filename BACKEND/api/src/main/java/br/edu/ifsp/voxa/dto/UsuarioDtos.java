package br.edu.ifsp.voxa.dto;

import br.edu.ifsp.voxa.model.Usuario;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.util.UUID;

public final class UsuarioDtos {

    private UsuarioDtos() {
    }

    public record UsuarioRequest(
            @NotBlank @Size(max = 120) String nome,
            @NotBlank @Email String email,
            @Pattern(regexp = "^[0-9()+\\-\\s]{10,20}$", message = "telefone inválido") String telefone,
            @Past LocalDate dataNascimento,
            String avatarUrl) {
    }

    public record UsuarioResponse(
            UUID id,
            String nome,
            String email,
            String telefone,
            LocalDate dataNascimento,
            String avatarUrl,
            int totalPerfis) {

        public static UsuarioResponse from(Usuario u) {
            return new UsuarioResponse(u.getId(), u.getNome(), u.getEmail(), u.getTelefone(),
                    u.getDataNascimento(), u.getAvatarUrl(), u.getPerfis().size());
        }
    }
}
