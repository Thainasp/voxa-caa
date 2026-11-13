package br.edu.ifsp.voxa.service;

import br.edu.ifsp.voxa.dto.PerfilDtos.PerfilResponse;
import br.edu.ifsp.voxa.dto.UsuarioDtos.UsuarioRequest;
import br.edu.ifsp.voxa.dto.UsuarioDtos.UsuarioResponse;
import br.edu.ifsp.voxa.exception.ConflitoException;
import br.edu.ifsp.voxa.exception.RecursoNaoEncontradoException;
import br.edu.ifsp.voxa.exception.RegraNegocioException;
import br.edu.ifsp.voxa.model.Perfil;
import br.edu.ifsp.voxa.model.Usuario;
import br.edu.ifsp.voxa.repository.UsuarioRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.Period;
import java.util.List;
import java.util.UUID;

@Service
public class UsuarioService {

    private final UsuarioRepository usuarios;

    public UsuarioService(UsuarioRepository usuarios) {
        this.usuarios = usuarios;
    }

    Usuario buscar(UUID id) {
        return usuarios.findById(id).orElseThrow(() -> new RecursoNaoEncontradoException("Usuário", id));
    }

    @Transactional(readOnly = true)
    public List<UsuarioResponse> listar() {
        return usuarios.findAll().stream().map(UsuarioResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public UsuarioResponse obter(UUID id) {
        return UsuarioResponse.from(buscar(id));
    }

    @Transactional(readOnly = true)
    public List<PerfilResponse> listarPerfis(UUID id) {
        return buscar(id).getPerfis().stream().map(PerfilResponse::from).toList();
    }

    /** Cria a conta e o perfil titular (responsável) numa única transação. */
    @Transactional
    public UsuarioResponse criar(UsuarioRequest req) {
        validarMaioridade(req.dataNascimento());
        if (usuarios.existsByEmailIgnoreCase(req.email())) {
            throw new ConflitoException("E-mail já cadastrado");
        }
        Usuario u = new Usuario();
        preencher(u, req);
        Perfil titular = new Perfil();
        titular.setUsuario(u);
        titular.setNome(req.nome());
        titular.setAvatarUrl(req.avatarUrl());
        titular.setResponsavel(true);
        u.getPerfis().add(titular);
        return UsuarioResponse.from(usuarios.save(u));
    }

    @Transactional
    public UsuarioResponse atualizar(UUID id, UsuarioRequest req) {
        validarMaioridade(req.dataNascimento());
        Usuario u = buscar(id);
        if (usuarios.existsByEmailIgnoreCaseAndIdNot(req.email(), id)) {
            throw new ConflitoException("E-mail já cadastrado");
        }
        preencher(u, req);
        return UsuarioResponse.from(u);
    }

    @Transactional
    public void excluir(UUID id) {
        usuarios.delete(buscar(id));
    }

    private void preencher(Usuario u, UsuarioRequest req) {
        u.setNome(req.nome().trim());
        u.setEmail(req.email().trim().toLowerCase());
        u.setTelefone(req.telefone());
        u.setDataNascimento(req.dataNascimento());
        u.setAvatarUrl(req.avatarUrl());
        u.setResponsavel(true);
    }

    /** RN-03: o responsável precisa ter 18 anos ou mais. */
    private void validarMaioridade(LocalDate nascimento) {
        if (nascimento != null && Period.between(nascimento, LocalDate.now()).getYears() < 18) {
            throw new RegraNegocioException("O responsável deve ter 18 anos ou mais (RN-03)");
        }
    }
}
