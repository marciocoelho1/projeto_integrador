package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.RegraAlertaResponse;
import br.com.senac.sgsst.exception.ApiExceptionHandler;
import br.com.senac.sgsst.exception.RecursoNaoEncontradoException;
import br.com.senac.sgsst.service.RegraAlertaService;
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

class RegraAlertaControllerTest {

  RegraAlertaService service;
  MockMvc mvc;

  @BeforeEach void setup() {
    service = mock(RegraAlertaService.class);
    mvc = MockMvcBuilders
      .standaloneSetup(new RegraAlertaController(service))
      .setControllerAdvice(new ApiExceptionHandler())
      .build();
  }

  @Test void listaRegras() throws Exception {
    when(service.listar()).thenReturn(java.util.List.of(
      new RegraAlertaResponse("estoqueEpi", "Ruptura de Estoque (EPI)", "Notificar...", true)
    ));

    mvc.perform(get("/api/regras-alerta"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$[0].codigo").value("estoqueEpi"))
      .andExpect(jsonPath("$[0].ativa").value(true));
  }

  @Test void alternaRegra() throws Exception {
    when(service.definirAtiva(eq("treinamentoVencido"), any()))
      .thenReturn(new RegraAlertaResponse("treinamentoVencido", "Reciclagem de NRs", "Aviso...", true));

    mvc.perform(put("/api/regras-alerta/treinamentoVencido")
      .contentType(MediaType.APPLICATION_JSON)
      .content("{\"ativa\": true}"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.ativa").value(true));
  }

  @Test void ativaAusenteRetorna400() throws Exception {
    mvc.perform(put("/api/regras-alerta/estoqueEpi")
      .contentType(MediaType.APPLICATION_JSON)
      .content("{}"))
      .andExpect(status().isBadRequest());

    verify(service, never()).definirAtiva(any(), any());
  }

  @Test void codigoInexistenteRetorna404() throws Exception {
    when(service.definirAtiva(eq("naoExiste"), any()))
      .thenThrow(new RecursoNaoEncontradoException("Regra de alerta não encontrada."));

    mvc.perform(put("/api/regras-alerta/naoExiste")
      .contentType(MediaType.APPLICATION_JSON)
      .content("{\"ativa\": false}"))
      .andExpect(status().isNotFound())
      .andExpect(jsonPath("$.mensagem").value("Regra de alerta não encontrada."));
  }
}
