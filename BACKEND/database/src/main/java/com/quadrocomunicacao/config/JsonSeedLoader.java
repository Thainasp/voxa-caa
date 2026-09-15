package com.quadrocomunicacao.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.quadrocomunicacao.dto.CartaoRequest;
import com.quadrocomunicacao.dto.CategoriaRequest;
import com.quadrocomunicacao.dto.PranchaRequest;
import com.quadrocomunicacao.dto.UsuarioRequest;
import com.quadrocomunicacao.model.Categoria;
import com.quadrocomunicacao.model.Prancha;
import com.quadrocomunicacao.model.Usuario;
import com.quadrocomunicacao.repository.CategoriaRepository;
import com.quadrocomunicacao.repository.PranchaRepository;
import com.quadrocomunicacao.repository.UsuarioRepository;
import com.quadrocomunicacao.service.CartaoService;
import com.quadrocomunicacao.service.CategoriaService;
import com.quadrocomunicacao.service.PranchaService;
import com.quadrocomunicacao.service.UsuarioService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.InputStream;
import java.util.List;

/**
 * Carrega uma massa inicial de dados a partir de resources/data/seed.json.
 *
 * So executa quando o profile "seed" esta ativo, para nao duplicar dados a
 * cada reinicio da aplicacao:
 *
 *   mvn spring-boot:run -Dspring-boot.run.profiles=seed
 */
@Component
@Profile("seed")
@RequiredArgsConstructor
@Slf4j
public class JsonSeedLoader implements CommandLineRunner {

    private final UsuarioService usuarioService;
    private final CategoriaService categoriaService;
    private final PranchaService pranchaService;
    private final CartaoService cartaoService;

    private final UsuarioRepository usuarioRepository;
    private final CategoriaRepository categoriaRepository;
    private final PranchaRepository pranchaRepository;

    @Override
    public void run(String... args) throws Exception {
        ObjectMapper mapper = new ObjectMapper().registerModule(new JavaTimeModule());

        try (InputStream is = new ClassPathResource("data/seed.json").getInputStream()) {
            SeedData seed = mapper.readValue(is, SeedData.class);

            for (UsuarioRequest u : seed.usuarios()) {
                usuarioService.cadastrar(u);
            }

            for (CategoriaRequest c : seed.categorias()) {
                categoriaService.criar(c);
            }

            for (PranchaSeedItem p : seed.pranchas()) {
                Usuario usuario = usuarioRepository.findByEmail(p.usuarioEmail())
                        .orElseThrow(() -> new IllegalStateException(
                                "Usuario nao encontrado no seed: " + p.usuarioEmail()));
                pranchaService.criar(new PranchaRequest(p.nome(), usuario.getId()));
            }

            for (CartaoSeedItem c : seed.cartoes()) {
                Categoria categoria = categoriaRepository.findByNome(c.categoriaNome())
                        .orElseThrow(() -> new IllegalStateException(
                                "Categoria nao encontrada no seed: " + c.categoriaNome()));
                Prancha prancha = pranchaRepository.findAll().stream()
                        .filter(pr -> pr.getNome().equals(c.pranchaNome()))
                        .findFirst()
                        .orElseThrow(() -> new IllegalStateException(
                                "Prancha nao encontrada no seed: " + c.pranchaNome()));

                cartaoService.adicionar(new CartaoRequest(
                        c.texto(), c.caminhoImagem(), c.caminhoAudio(),
                        c.isFavorito(), c.frequenciaUso(),
                        categoria.getId(), prancha.getId()));
            }

            log.info("Seed concluido: {} usuarios, {} categorias, {} pranchas, {} cartoes",
                    seed.usuarios().size(), seed.categorias().size(),
                    seed.pranchas().size(), seed.cartoes().size());
        }
    }

    // Estrutura do arquivo seed.json. Pranchas/cartoes usam chaves "naturais"
    // (email, nome) em vez de ids, ja que os ids reais so existem depois do insert.
    private record SeedData(
            List<UsuarioRequest> usuarios,
            List<CategoriaRequest> categorias,
            List<PranchaSeedItem> pranchas,
            List<CartaoSeedItem> cartoes
    ) {}

    private record PranchaSeedItem(String nome, String usuarioEmail) {}

    private record CartaoSeedItem(
            String texto,
            String caminhoImagem,
            String caminhoAudio,
            Boolean isFavorito,
            Integer frequenciaUso,
            String categoriaNome,
            String pranchaNome
    ) {}
}
