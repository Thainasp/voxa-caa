package br.edu.ifsp.voxa;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.web.servlet.MockMvc;

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

    @Autowired
    MockMvc mvc;

    @Test
    void relacionamentoUmParaMuitosUsuarioPerfis() throws Exception {
        mvc.perform(get("/api/v1/usuarios/{id}/perfis", USUARIO))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)));
    }

    @Test
    void relacionamentoMuitosParaMuitosPranchaCartao() throws Exception {
        mvc.perform(put("/api/v1/pranchas/{id}/cartoes/{cartao}", ROTINA, COMER)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"ordem\":3}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.ordem").value(3));
        mvc.perform(get("/api/v1/pranchas/{id}", ROTINA))
                .andExpect(jsonPath("$.cartoes", hasSize(4)));
        mvc.perform(delete("/api/v1/pranchas/{id}/cartoes/{cartao}", ROTINA, COMER))
                .andExpect(status().isNoContent());
    }

    @Test
    void crudCartaoComValidacao() throws Exception {
        mvc.perform(post("/api/v1/cartoes").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"perfilId\":\"" + LEO + "\",\"texto\":\"Brincar\",\"corHex\":\"#ff2e9e4f\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.texto").value("Brincar"));
        mvc.perform(post("/api/v1/cartoes").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"perfilId\":\"" + LEO + "\",\"texto\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.campos[0].campo").value("texto"));
    }

    @Test
    void naoExcluiPerfilResponsavel() throws Exception {
        mvc.perform(delete("/api/v1/perfis/{id}", TITULAR)).andExpect(status().isConflict());
        mvc.perform(delete("/api/v1/perfis/{id}", LEO)).andExpect(status().isNoContent());
        mvc.perform(get("/api/v1/perfis/{id}", LEO)).andExpect(status().isNotFound());
    }

    @Test
    void responsavelPrecisaSerMaiorDeIdade() throws Exception {
        mvc.perform(post("/api/v1/usuarios").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nome\":\"Ana\",\"email\":\"ana@voxa.app\",\"dataNascimento\":\"2015-01-01\"}"))
                .andExpect(status().isUnprocessableEntity());
    }
}
