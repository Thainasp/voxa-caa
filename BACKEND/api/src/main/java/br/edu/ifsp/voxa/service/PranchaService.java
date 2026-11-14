package br.edu.ifsp.voxa.service;

import br.edu.ifsp.voxa.dto.PranchaDtos.PranchaCartaoResponse;
import br.edu.ifsp.voxa.dto.PranchaDtos.PranchaRequest;
import br.edu.ifsp.voxa.dto.PranchaDtos.PranchaResponse;
import br.edu.ifsp.voxa.exception.ConflitoException;
import br.edu.ifsp.voxa.exception.RecursoNaoEncontradoException;
import br.edu.ifsp.voxa.exception.RegraNegocioException;
import br.edu.ifsp.voxa.model.Cartao;
import br.edu.ifsp.voxa.model.Prancha;
import br.edu.ifsp.voxa.model.PranchaCartao;
import br.edu.ifsp.voxa.model.PranchaCartaoId;
import br.edu.ifsp.voxa.repository.PranchaCartaoRepository;
import br.edu.ifsp.voxa.repository.PranchaRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class PranchaService {

    private final PranchaRepository pranchas;
    private final PranchaCartaoRepository itens;
    private final PerfilService perfilService;
    private final CartaoService cartaoService;

    public PranchaService(PranchaRepository pranchas, PranchaCartaoRepository itens,
                          PerfilService perfilService, CartaoService cartaoService) {
        this.pranchas = pranchas;
        this.itens = itens;
        this.perfilService = perfilService;
        this.cartaoService = cartaoService;
    }

    Prancha buscar(UUID id) {
        return pranchas.findById(id).orElseThrow(() -> new RecursoNaoEncontradoException("Prancha", id));
    }

    @Transactional(readOnly = true)
    public List<PranchaResponse> listar(UUID perfilId, UUID usuarioId) {
        List<Prancha> lista;
        if (perfilId == null) {
            lista = pranchas.findByPerfilUsuarioIdAndCatalogoArasaacFalseOrderByOrdemAsc(usuarioId);
        } else {
            perfilService.buscarDoUsuario(perfilId, usuarioId);
            lista = pranchas.findByPerfilIdAndCatalogoArasaacFalseOrderByOrdemAsc(perfilId);
        }
        return lista.stream().map(p -> PranchaResponse.from(p, false)).toList();
    }

    @Transactional(readOnly = true)
    public PranchaResponse obter(UUID id, UUID usuarioId) {
        Prancha prancha = buscarDoUsuario(id, usuarioId);
        return PranchaResponse.from(prancha, true);
    }

    @Transactional
    public PranchaResponse criar(PranchaRequest req, UUID usuarioId) {
        perfilService.buscarDoUsuario(req.perfilId(), usuarioId);
        if (pranchas.existsByPerfilIdAndChave(req.perfilId(), req.chave())) {
            throw new ConflitoException("Já existe uma prancha com a chave '" + req.chave() + "' neste perfil");
        }
        Prancha p = new Prancha();
        p.setId(req.id() == null ? UUID.randomUUID() : req.id());
        p.setPerfil(perfilService.buscar(req.perfilId()));
        p.setChave(req.chave().trim());
        preencher(p, req);
        return PranchaResponse.from(pranchas.save(p), true);
    }

    @Transactional
    public PranchaResponse salvar(UUID id, PranchaRequest req, UUID usuarioId) {
        if (req.id() != null && !req.id().equals(id)) {
            throw new RegraNegocioException("O identificador do corpo não corresponde à URL");
        }
        perfilService.buscarDoUsuario(req.perfilId(), usuarioId);
        Prancha p = pranchas.findById(id).orElseGet(Prancha::new);
        if (p.getId() == null) {
            p.setId(id);
            p.setPerfil(perfilService.buscar(req.perfilId()));
        } else {
            perfilService.buscarDoUsuario(p.getPerfil().getId(), usuarioId);
            if (!p.getPerfil().getId().equals(req.perfilId())) {
                throw new RegraNegocioException("Não é permitido mover a prancha para outro perfil");
            }
        }
        if (pranchas.existsByPerfilIdAndChaveAndIdNot(req.perfilId(), req.chave(), id)) {
            throw new ConflitoException("Já existe uma prancha com a chave '" + req.chave() + "' neste perfil");
        }
        p.setChave(req.chave().trim());
        preencher(p, req);
        return PranchaResponse.from(pranchas.save(p), true);
    }

    @Transactional
    public void excluir(UUID id, UUID usuarioId) {
        pranchas.delete(buscarDoUsuario(id, usuarioId));
    }

    // ---- Relacionamento N:N (prancha_cartao) --------------------------------

    @Transactional(readOnly = true)
    public List<PranchaCartaoResponse> listarCartoes(UUID pranchaId, UUID usuarioId) {
        buscarDoUsuario(pranchaId, usuarioId);
        return itens.findByPranchaIdOrderByOrdemAsc(pranchaId).stream().map(PranchaCartaoResponse::from).toList();
    }

    /** Adiciona o cartão à prancha ou atualiza a ordem se ele já estiver nela. */
    @Transactional
    public PranchaCartaoResponse vincular(UUID pranchaId, UUID cartaoId, int ordem, UUID usuarioId) {
        Prancha prancha = buscarDoUsuario(pranchaId, usuarioId);
        Cartao cartao = cartaoService.buscarDoUsuario(cartaoId, usuarioId);
        if (!prancha.getPerfil().getId().equals(cartao.getPerfil().getId())) {
            throw new RegraNegocioException("Cartão e prancha precisam pertencer ao mesmo perfil");
        }
        PranchaCartao item = itens.findById(new PranchaCartaoId(pranchaId, cartaoId))
                .orElseGet(() -> {
                    PranchaCartao novo = new PranchaCartao(prancha, cartao, ordem);
                    prancha.getItens().add(novo);
                    return novo;
                });
        item.setOrdem(ordem);
        return PranchaCartaoResponse.from(item);
    }

    @Transactional
    public void desvincular(UUID pranchaId, UUID cartaoId, UUID usuarioId) {
        buscarDoUsuario(pranchaId, usuarioId);
        cartaoService.buscarDoUsuario(cartaoId, usuarioId);
        PranchaCartao item = itens.findById(new PranchaCartaoId(pranchaId, cartaoId))
                .orElseThrow(() -> new RecursoNaoEncontradoException("Cartão na prancha", cartaoId));
        item.getPrancha().getItens().remove(item);
        itens.delete(item);
    }

    private Prancha buscarDoUsuario(UUID id, UUID usuarioId) {
        return pranchas.findByIdAndPerfilUsuarioId(id, usuarioId)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Prancha", id));
    }

    private void preencher(Prancha p, PranchaRequest req) {
        p.setNome(req.nome().trim());
        p.setIcone(req.icone());
        p.setImagemUrl(req.imagemUrl());
        p.setImagemStoragePath(req.imagemStoragePath());
        p.setCaminhoAudio(req.caminhoAudio());
        p.setOrdem(req.ordem() == null ? 0 : req.ordem());
    }
}
