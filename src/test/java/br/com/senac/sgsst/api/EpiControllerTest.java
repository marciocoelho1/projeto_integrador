package br.com.senac.sgsst.api;
import br.com.senac.sgsst.dto.*;
import br.com.senac.sgsst.service.EpiService;
import br.com.senac.sgsst.exception.*;
import static org.mockito.Mockito.*;
class EpiControllerTest extends CrudControllerContractTest {
  EpiService service;
  Object controller() {
    service = mock(EpiService.class);
    var response = new EpiResponse(1, "Capacete", "123", java.time.LocalDate.of(2026,1,1), java.time.LocalDate.of(2027,1,1), 0);
    when(service.listar()).thenReturn(java.util.List.of(response));
    when(service.buscarPorId(1)).thenReturn(response);
    when(service.criar(any())).thenReturn(response);
    when(service.atualizar(eq(1), any())).thenReturn(response);
    when(service.buscarPorId(404)).thenThrow(new RecursoNaoEncontradoException("Não encontrado."));
    when(service.atualizar(eq(404), any())).thenThrow(new RecursoNaoEncontradoException("Não encontrado."));
    doThrow(new RecursoNaoEncontradoException("Não encontrado.")).when(service).excluir(404);
    return new EpiController(service);
  }
  String endpoint() { return "/api/epis"; }
  String payload() { return "{\"descricao\": \"Capacete\", \"ca\": \"123\", \"inclusao\": \"2026-01-01\", \"validade\": \"2027-01-01\", \"quantidade\": 0}"; }
  void conflict() { when(service.criar(any())).thenThrow(new org.springframework.dao.DataIntegrityViolationException("test")); }
  @org.junit.jupiter.api.Test void campoInvalidoRetorna400() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload().replace("\"quantidade\": 0", "\"quantidade\": -1")))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }

  @org.junit.jupiter.api.Test void dataInvalidaRetorna400() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload().replace("2026-01-01", "2026-02-30")))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }
}
