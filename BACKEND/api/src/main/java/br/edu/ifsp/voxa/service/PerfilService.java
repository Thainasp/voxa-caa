package br.edu.ifsp.voxa.service;

import br.edu.ifsp.voxa.dto.PerfilDtos.PerfilRequest;
import br.edu.ifsp.voxa.dto.PerfilDtos.PerfilResponse;
import br.edu.ifsp.voxa.dto.PerfilDtos.PerfilUpdateRequest;
import br.edu.ifsp.voxa.exception.ConflitoException;
import br.edu.ifsp.voxa.exception.RecursoNaoEncontradoException;
import br.edu.ifsp.voxa.model.Perfil;
import br.edu.ifsp.voxa.model.Usuario;
import br.edu.ifsp.voxa.repository.PerfilRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class PerfilService {

    private final PerfilRepository perfis;
    private final UsuarioService usuarioService;

    public PerfilService(PerfilRepository perfis, UsuarioService usuarioService) {
        this.perfis = perfis;
        this.usuarioService = usuarioService;
    }

    Perfil buscar(UUID id) {
        return perfis.findById(id).orElseThrow(() -> new RecursoNaoEncontradoException("Perfil", id));
    }

    @Transactional(readOnly = true)
    public List<PerfilResponse> listar(UUID usuarioId) {
        List<Perfil> lista = usuarioId == null ? perfis.findAll() : perfis.findByUsuarioIdOrderByNomeAsc(usuarioId);
        return lista.stream().map(PerfilResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public PerfilResponse obter(UUID id) {
        return PerfilResponse.from(buscar(id));
    }

    @Transactional
    public PerfilResponse criar(PerfilRequest req) {
        Usuario usuario = usuarioService.buscar(req.usuarioId());
        boolean responsavel = Boolean.TRUE.equals(req.responsavel());
        if (responsavel && perfis.existsByUsuarioIdAndResponsavelTrue(usuario.getId())) {
            throw new ConflitoException("A conta já possui um perfil responsável");
        }
        Perfil p = new Perfil();
        p.setUsuario(usuario);
        p.setNome(req.nome().trim());
        p.setAvatarUrl(req.avatarUrl());
        p.setResponsavel(responsavel);
        return PerfilResponse.from(perfis.save(p));
    }

    @Transactional
    public PerfilResponse atualizar(UUID id, PerfilUpdateRequest req) {
        Perfil p = buscar(id);
        p.setNome(req.nome().trim());
        p.setAvatarUrl(req.avatarUrl());
        return PerfilResponse.from(p);
    }

    /** O perfil responsável só sai junto com a conta (DELETE /usuarios/{id}). */
    @Transactional
    public void excluir(UUID id) {
        Perfil p = buscar(id);
        if (Boolean.TRUE.equals(p.getResponsavel())) {
            throw new ConflitoException("O perfil responsável não pode ser excluído");
        }
        p.getUsuario().getPerfis().remove(p);
        perfis.delete(p);
    }
}
