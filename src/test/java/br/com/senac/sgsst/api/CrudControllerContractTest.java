package br.com.senac.sgsst.api;

import br.com.senac.sgsst.exception.ApiExceptionHandler;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

abstract class CrudControllerContractTest {
  MockMvc mvc;
  abstract Object controller();
  abstract String endpoint();
  abstract String payload();
  abstract void conflict();
  @BeforeEach void setup() { mvc = MockMvcBuilders.standaloneSetup(controller()).setControllerAdvice(new ApiExceptionHandler()).build(); }
  @Test void lista() throws Exception {
    mvc.perform(get(endpoint())).andExpect(status().isOk()).andExpect(content().json("[" + response() + "]"));
  }
  @Test void buscaIdNumerico() throws Exception {
    mvc.perform(get(endpoint() + "/1")).andExpect(status().isOk()).andExpect(content().json(response()));
  }
  @Test void criaComLocationETodosOsCampos() throws Exception {
    mvc.perform(post(endpoint()).contentType(MediaType.APPLICATION_JSON).content(payload()))
      .andExpect(status().isCreated()).andExpect(header().string("Location", endpoint() + "/1"))
      .andExpect(content().json(response()));
  }
  @Test void atualiza() throws Exception {
    mvc.perform(put(endpoint() + "/1").contentType(MediaType.APPLICATION_JSON).content(payload()))
      .andExpect(status().isOk()).andExpect(content().json(response()));
  }
  @Test void excluiSemCorpo() throws Exception {
    mvc.perform(delete(endpoint() + "/1")).andExpect(status().isNoContent()).andExpect(content().string(""));
  }
  @Test void camposObrigatoriosInvalidosRetornam400() throws Exception {
    mvc.perform(post(endpoint()).contentType(MediaType.APPLICATION_JSON).content("{}"))
      .andExpect(status().isBadRequest()).andExpect(jsonPath("$.detalhes").isArray());
    mvc.perform(put(endpoint() + "/1").contentType(MediaType.APPLICATION_JSON).content("{}"))
      .andExpect(status().isBadRequest());
  }
  @Test void idInvalidoRetorna400() throws Exception {
    mvc.perform(get(endpoint() + "/abc")).andExpect(status().isBadRequest());
  }
  @Test void jsonInvalidoRetorna400() throws Exception {
    mvc.perform(post(endpoint()).contentType(MediaType.APPLICATION_JSON).content("{"))
      .andExpect(status().isBadRequest());
  }
  @Test void inexistenteRetorna404() throws Exception {
    mvc.perform(get(endpoint() + "/404")).andExpect(status().isNotFound()).andExpect(jsonPath("$.mensagem").exists());
    mvc.perform(put(endpoint() + "/404").contentType(MediaType.APPLICATION_JSON).content(payload())).andExpect(status().isNotFound());
    mvc.perform(delete(endpoint() + "/404")).andExpect(status().isNotFound());
  }
  @Test void conflitoRetorna409() throws Exception {
    conflict();
    mvc.perform(post(endpoint()).contentType(MediaType.APPLICATION_JSON).content(payload()))
      .andExpect(status().isConflict()).andExpect(jsonPath("$.mensagem").exists());
  }
  private String response() { return "{\"id\":1," + payload().substring(1); }
}
