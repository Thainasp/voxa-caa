package br.edu.ifsp.voxa.dto;

import br.edu.ifsp.voxa.model.Cartao;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public final class CartaoDtos {

    private CartaoDtos() {
    }

    public record CartaoRequest(
            @NotNull UUID perfilId,
            @NotBlank @Size(max = 80) String texto,
            String caminhoImagem,
            String caminhoAudio,
            String icone,
            @Pattern(regexp = "^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$", message = "cor deve estar no formato #RRGGBB ou #AARRGGBB")
            String corHex,
            String arasaacId,
            Boolean favorito) {
    }

    public record CartaoResponse(
            UUID id,
            UUID perfilId,
            String texto,
            String caminhoImagem,
            String caminhoAudio,
            String icone,
            String corHex,
            String arasaacId,
            boolean favorito,
            int frequenciaUso) {

        public static CartaoResponse from(Cartao c) {
            return new CartaoResponse(c.getId(), c.getPerfil().getId(), c.getTexto(), c.getCaminhoImagem(),
                    c.getCaminhoAudio(), c.getIcone(), c.getCorHex(), c.getArasaacId(),
                    Boolean.TRUE.equals(c.getFavorito()),
                    c.getFrequenciaUso() == null ? 0 : c.getFrequenciaUso());
        }
    }
}
