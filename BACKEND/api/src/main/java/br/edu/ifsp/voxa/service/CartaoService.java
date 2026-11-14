package br.edu.ifsp.voxa.service;

import br.edu.ifsp.voxa.dto.CartaoDtos.CartaoRequest;
import br.edu.ifsp.voxa.dto.CartaoDtos.CartaoResponse;
import br.edu.ifsp.voxa.exception.RecursoNaoEncontradoException;
import br.edu.ifsp.voxa.exception.RegraNegocioException;
import br.edu.ifsp.voxa.model.Cartao;
import br.edu.ifsp.voxa.repository.CartaoRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class CartaoService {

    private final CartaoRepository cartoes;
    private final PerfilService perfilService;

    public CartaoService(CartaoRepository cartoes, PerfilService perfilService) {
        this.cartoes = cartoes;
        this.perfilService = perfilService;
    }

    Cartao buscar(UUID id) {
        return cartoes.findById(id).orElseThrow(() -> new RecursoNaoEncontradoException("Cartão", id));
    }

    public Cartao buscarDoUsuario(UUID id, UUID usuarioId) {
        return cartoes.findByIdAndPerfilUsuarioId(id, usuarioId)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Cartão", id));
    }

    /** RF06: busca textual opcional. */
    @Transactional(readOnly = true)
    public List<CartaoResponse> listar(UUID perfilId, String busca, UUID usuarioId) {
        List<Cartao> lista;
        if (perfilId == null) {
            lista = cartoes.findByPerfilUsuarioIdOrderByTextoAsc(usuarioId);
        } else if (busca == null || busca.isBlank()) {
            perfilService.buscarDoUsuario(perfilId, usuarioId);
            lista = cartoes.findByPerfilIdOrderByTextoAsc(perfilId);
        } else {
            perfilService.buscarDoUsuario(perfilId, usuarioId);
            lista = cartoes.findByPerfilIdAndTextoContainingIgnoreCaseOrderByTextoAsc(perfilId, busca.trim());
        }
        return lista.stream().map(CartaoResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public CartaoResponse obter(UUID id, UUID usuarioId) {
        return CartaoResponse.from(buscarDoUsuario(id, usuarioId));
    }

    @Transactional
    public CartaoResponse criar(CartaoRequest req, UUID usuarioId) {
        perfilService.buscarDoUsuario(req.perfilId(), usuarioId);
        Cartao c = new Cartao();
        c.setId(req.id() == null ? UUID.randomUUID() : req.id());
        c.setPerfil(perfilService.buscar(req.perfilId()));
        preencher(c, req);
        return CartaoResponse.from(cartoes.save(c));
    }

    @Transactional
    public CartaoResponse salvar(UUID id, CartaoRequest req, UUID usuarioId) {
        if (req.id() != null && !req.id().equals(id)) {
            throw new RegraNegocioException("O identificador do corpo não corresponde à URL");
        }
        perfilService.buscarDoUsuario(req.perfilId(), usuarioId);
        Cartao c = cartoes.findById(id).orElseGet(Cartao::new);
        if (c.getId() == null) {
            c.setId(id);
            c.setPerfil(perfilService.buscar(req.perfilId()));
        } else {
            perfilService.buscarDoUsuario(c.getPerfil().getId(), usuarioId);
            if (!c.getPerfil().getId().equals(req.perfilId())) {
                throw new RegraNegocioException("Não é permitido mover o cartão para outro perfil");
            }
        }
        preencher(c, req);
        return CartaoResponse.from(cartoes.save(c));
    }

    @Transactional(readOnly = true)
    public List<UUID> listarPranchas(UUID cartaoId, UUID usuarioId) {
        Cartao cartao = buscarDoUsuario(cartaoId, usuarioId);
        return cartao.getPranchas().stream()
                .map(item -> item.getPrancha().getId())
                .toList();
    }

    /** Remove também os vínculos com pranchas (cascade REMOVE em PranchaCartao). */
    @Transactional
    public void excluir(UUID id, UUID usuarioId) {
        cartoes.delete(buscarDoUsuario(id, usuarioId));
    }

    private void preencher(Cartao c, CartaoRequest req) {
        c.setTexto(req.texto().trim());
        c.setCaminhoImagem(req.caminhoImagem());
        c.setImagemStoragePath(req.imagemStoragePath());
        c.setCaminhoAudio(req.caminhoAudio());
        c.setIcone(req.icone());
        c.setCorHex(req.corHex() == null ? "#fff08a3c" : req.corHex());
        c.setArasaacId(req.arasaacId());
        c.setFavorito(Boolean.TRUE.equals(req.favorito()));
    }
}
