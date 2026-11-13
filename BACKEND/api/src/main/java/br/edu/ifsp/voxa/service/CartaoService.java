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

    /** RF06: busca textual opcional. */
    @Transactional(readOnly = true)
    public List<CartaoResponse> listar(UUID perfilId, String busca) {
        List<Cartao> lista;
        if (perfilId == null) {
            lista = cartoes.findAll();
        } else if (busca == null || busca.isBlank()) {
            lista = cartoes.findByPerfilIdOrderByTextoAsc(perfilId);
        } else {
            lista = cartoes.findByPerfilIdAndTextoContainingIgnoreCaseOrderByTextoAsc(perfilId, busca.trim());
        }
        return lista.stream().map(CartaoResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public CartaoResponse obter(UUID id) {
        return CartaoResponse.from(buscar(id));
    }

    @Transactional
    public CartaoResponse criar(CartaoRequest req) {
        Cartao c = new Cartao();
        c.setPerfil(perfilService.buscar(req.perfilId()));
        preencher(c, req);
        return CartaoResponse.from(cartoes.save(c));
    }

    @Transactional
    public CartaoResponse atualizar(UUID id, CartaoRequest req) {
        Cartao c = buscar(id);
        if (!c.getPerfil().getId().equals(req.perfilId())) {
            throw new RegraNegocioException("Não é permitido mover o cartão para outro perfil");
        }
        preencher(c, req);
        return CartaoResponse.from(c);
    }

    /** Remove também os vínculos com pranchas (cascade REMOVE em PranchaCartao). */
    @Transactional
    public void excluir(UUID id) {
        cartoes.delete(buscar(id));
    }

    private void preencher(Cartao c, CartaoRequest req) {
        c.setTexto(req.texto().trim());
        c.setCaminhoImagem(req.caminhoImagem());
        c.setCaminhoAudio(req.caminhoAudio());
        c.setIcone(req.icone());
        c.setCorHex(req.corHex() == null ? "#fff08a3c" : req.corHex());
        c.setArasaacId(req.arasaacId());
        c.setFavorito(Boolean.TRUE.equals(req.favorito()));
    }
}
