package br.edu.ifsp.voxa;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class VoxaApiIntegrationTest {

    private static final String USUARIO = "11111111-1111-4111-8111-111111111111";
    private static final String TITULAR = "22222222-2222-4222-8222-222222222221";
    private static final String LEO = "22222222-2222-4222-8222-222222222222";
    private static final String ROTINA = "33333333-3333-4333-8333-333333333331";
    private static final String COMER = "44444444-4444-4444-8444-444444444443";
    private static final String CARTAO_CRIADO = "55555555-5555-4555-8555-555555555555";
    private static final String PRANCHA_OFFLINE = "66666666-6666-4666-8666-666666666666";

    @Autowired
    MockMvc mvc;

    @Test
    void relacionamentoUmParaMuitosUsuarioPerfis() throws Exception {
        mvc.perform(get("/api/v1/usuarios/{id}/perfis", USUARIO)
                        .with(jwt().jwt(token -> token.subject(USUARIO))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)));
    }

    @Test
    void relacionamentoMuitosParaMuitosPranchaCartao() throws Exception {
        mvc.perform(put("/api/v1/pranchas/{id}/cartoes/{cartao}", ROTINA, COMER)
                        .with(jwt().jwt(token -> token.subject(USUARIO)))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"ordem\":3}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.ordem").value(3));
        mvc.perform(get("/api/v1/pranchas/{id}", ROTINA)
                        .with(jwt().jwt(token -> token.subject(USUARIO))))
                .andExpect(jsonPath("$.cartoes", hasSize(4)));
        mvc.perform(delete("/api/v1/pranchas/{id}/cartoes/{cartao}", ROTINA, COMER)
                        .with(jwt().jwt(token -> token.subject(USUARIO))))
                .andExpect(status().isNoContent());
    }

    @Test
    void crudCartaoComValidacao() throws Exception {
        mvc.perform(post("/api/v1/cartoes").contentType(MediaType.APPLICATION_JSON)
                        .with(jwt().jwt(token -> token.subject(USUARIO)))
                        .content("{\"id\":\"" + CARTAO_CRIADO + "\",\"perfilId\":\"" + LEO
                                + "\",\"texto\":\"Brincar\",\"corHex\":\"#ff2e9e4f\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.texto").value("Brincar"))
                .andExpect(jsonPath("$.id").value(CARTAO_CRIADO));
        mvc.perform(post("/api/v1/cartoes").contentType(MediaType.APPLICATION_JSON)
                        .with(jwt().jwt(token -> token.subject(USUARIO)))
                        .content("{\"perfilId\":\"" + LEO + "\",\"texto\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.campos[0].campo").value("texto"));
    }

    @Test
    void conteudoExigeTokenEIsolaPerfisPorResponsavel() throws Exception {
        mvc.perform(get("/api/v1/pranchas").param("perfilId", LEO))
                .andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/pranchas").param("perfilId", LEO)
                        .with(jwt().jwt(token -> token.subject("99999999-9999-4999-8999-999999999999"))))
                .andExpect(status().isNotFound());
    }

    @Test
    void usuariosEPerfisExigemTokenEIsolamDadosPorResponsavel() throws Exception {
        mvc.perform(get("/api/v1/usuarios")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/perfis")).andExpect(status().isUnauthorized());

        mvc.perform(get("/api/v1/usuarios/{id}", USUARIO)
                        .with(jwt().jwt(token -> token.subject("99999999-9999-4999-8999-999999999999"))))
                .andExpect(status().isNotFound());
        mvc.perform(get("/api/v1/perfis/{id}", LEO)
                        .with(jwt().jwt(token -> token.subject("99999999-9999-4999-8999-999999999999"))))
                .andExpect(status().isNotFound());

        mvc.perform(get("/api/v1/usuarios")
                        .with(jwt().jwt(token -> token.subject(USUARIO))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)));
        mvc.perform(get("/api/v1/perfis")
                        .with(jwt().jwt(token -> token.subject(USUARIO))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)));
    }

    @Test
    void cadastroDaApiUsaOIdDoToken() throws Exception {
        String novoUsuario = "99999999-9999-4999-8999-999999999999";
        mvc.perform(post("/api/v1/usuarios").contentType(MediaType.APPLICATION_JSON)
                        .with(jwt().jwt(token -> token.subject(novoUsuario)))
                        .content("{\"nome\":\"Ana\",\"email\":\"ana@voxa.app\",\"dataNascimento\":\"1990-01-01\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(novoUsuario));
    }

    @Test
    void putCriaEAtualizaPranchaComIdLocalEstavel() throws Exception {
        String body = "{\"id\":\"" + PRANCHA_OFFLINE + "\",\"perfilId\":\"" + LEO
                + "\",\"chave\":\"offline\",\"nome\":\"Offline\",\"ordem\":1}";
        mvc.perform(put("/api/v1/pranchas/{id}", PRANCHA_OFFLINE)
                        .with(jwt().jwt(token -> token.subject(USUARIO)))
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(PRANCHA_OFFLINE));

        mvc.perform(put("/api/v1/pranchas/{id}", PRANCHA_OFFLINE)
                        .with(jwt().jwt(token -> token.subject(USUARIO)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body.replace("\"Offline\"", "\"Atualizada\"")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nome").value("Atualizada"));
    }

    @Test
    void naoExcluiPerfilResponsavel() throws Exception {
        mvc.perform(delete("/api/v1/perfis/{id}", TITULAR)
                        .with(jwt().jwt(token -> token.subject(USUARIO))))
                .andExpect(status().isConflict());
        mvc.perform(delete("/api/v1/perfis/{id}", LEO)
                        .with(jwt().jwt(token -> token.subject(USUARIO))))
                .andExpect(status().isNoContent());
        mvc.perform(get("/api/v1/perfis/{id}", LEO)
                        .with(jwt().jwt(token -> token.subject(USUARIO))))
                .andExpect(status().isNotFound());
    }

    @Test
    void responsavelPrecisaSerMaiorDeIdade() throws Exception {
        mvc.perform(post("/api/v1/usuarios").contentType(MediaType.APPLICATION_JSON)
                        .with(jwt().jwt(token -> token.subject(USUARIO)))
                        .content("{\"nome\":\"Ana\",\"email\":\"ana@voxa.app\",\"dataNascimento\":\"2015-01-01\"}"))
                .andExpect(status().isUnprocessableEntity());
    }
}
