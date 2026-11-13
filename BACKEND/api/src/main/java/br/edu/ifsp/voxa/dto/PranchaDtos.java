package br.edu.ifsp.voxa.dto;

import br.edu.ifsp.voxa.model.Prancha;
import br.edu.ifsp.voxa.model.PranchaCartao;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

public final class PranchaDtos {

    private PranchaDtos() {
    }

    public record PranchaRequest(
            @NotNull UUID perfilId,
            @NotBlank @Size(max = 60) String chave,
            @NotBlank @Size(max = 80) String nome,
            String icone,
            String imagemUrl,
            String caminhoAudio,
            @Min(0) Integer ordem) {
    }

    public record PranchaCartaoRequest(@NotNull @Min(0) Integer ordem) {
    }

    public record PranchaCartaoResponse(UUID cartaoId, String texto, String corHex, String caminhoImagem, int ordem) {
        public static PranchaCartaoResponse from(PranchaCartao pc) {
            return new PranchaCartaoResponse(pc.getCartao().getId(), pc.getCartao().getTexto(),
                    pc.getCartao().getCorHex(), pc.getCartao().getCaminhoImagem(),
                    pc.getOrdem() == null ? 0 : pc.getOrdem());
        }
    }

    public record PranchaResponse(
            UUID id,
            UUID perfilId,
            String chave,
            String nome,
            String icone,
            String imagemUrl,
            String caminhoAudio,
            int ordem,
            List<PranchaCartaoResponse> cartoes) {

        public static PranchaResponse from(Prancha p, boolean comCartoes) {
            return new PranchaResponse(p.getId(), p.getPerfil().getId(), p.getChave(), p.getNome(), p.getIcone(),
                    p.getImagemUrl(), p.getCaminhoAudio(), p.getOrdem() == null ? 0 : p.getOrdem(),
                    comCartoes ? p.getItens().stream().map(PranchaCartaoResponse::from).toList() : null);
        }
    }
}
