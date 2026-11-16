package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.ParametroResponse;
import br.com.senac.sgsst.exception.ApiExceptionHandler;
import br.com.senac.sgsst.exception.RecursoNaoEncontradoException;
import br.com.senac.sgsst.service.ParametroService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class ParametroControllerTest {

  ParametroService service;
  MockMvc mvc;

  @BeforeEach void setup() {
    service = mock(ParametroService.class);
    mvc = MockMvcBuilders
      .standaloneSetup(new ParametroController(service))
      .setControllerAdvice(new ApiExceptionHandler())
      .build();
  }

  @Test void listaParametros() throws Exception {
    when(service.listar()).thenReturn(java.util.List.of(
      new ParametroResponse("estoqueMinimoEpi", "5", "Estoque mínimo")
    ));

    mvc.perform(get("/api/parametros"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$[0].chave").value("estoqueMinimoEpi"))
      .andExpect(jsonPath("$[0].valor").value("5"));
  }

  @Test void atualizaValorDoParametro() throws Exception {
    when(service.atualizar(eq("estoqueMinimoEpi"), any()))
      .thenReturn(new ParametroResponse("estoqueMinimoEpi", "10", "Estoque mínimo"));

    mvc.perform(put("/api/parametros/estoqueMinimoEpi")
      .contentType(MediaType.APPLICATION_JSON)
      .content("{\"valor\": \"10\"}"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.valor").value("10"));
  }

  @Test void valorEmBrancoRetorna400() throws Exception {
    mvc.perform(put("/api/parametros/estoqueMinimoEpi")
      .contentType(MediaType.APPLICATION_JSON)
      .content("{\"valor\": \"   \"}"))
      .andExpect(status().isBadRequest());

    verify(service, never()).atualizar(any(), any());
  }

  @Test void chaveInexistenteRetorna404() throws Exception {
    when(service.atualizar(eq("naoExiste"), any()))
      .thenThrow(new RecursoNaoEncontradoException("Parâmetro não encontrado."));

    mvc.perform(put("/api/parametros/naoExiste")
      .contentType(MediaType.APPLICATION_JSON)
      .content("{\"valor\": \"1\"}"))
      .andExpect(status().isNotFound())
      .andExpect(jsonPath("$.mensagem").value("Parâmetro não encontrado."));
  }
}
