package br.com.senac.sgsst.api;
import br.com.senac.sgsst.dto.*;
import br.com.senac.sgsst.service.EpiEntregaService;
import br.com.senac.sgsst.exception.*;
import static org.mockito.Mockito.*;
class EpiEntregaControllerTest extends CrudControllerContractTest {
  EpiEntregaService service;
  Object controller() {
    service = mock(EpiEntregaService.class);
    var response = new EpiEntregaResponse(1, 1, "Ana Ribeiro", "M01", 7, "Capacete", "123", 2, java.time.LocalDate.of(2026,6,1), "Ana Ribeiro", java.time.Instant.parse("2026-06-01T10:00:00Z"));
    when(service.listar(null)).thenReturn(java.util.List.of(response));
    when(service.listar(1)).thenReturn(java.util.List.of(response));
    when(service.buscarPorId(1)).thenReturn(response);
    when(service.registrar(any())).thenReturn(response);
    when(service.atualizar(eq(1), any())).thenReturn(response);
    when(service.buscarPorId(404)).thenThrow(new RecursoNaoEncontradoException("Não encontrado."));
    when(service.atualizar(eq(404), any())).thenThrow(new RecursoNaoEncontradoException("Não encontrado."));
    doThrow(new RecursoNaoEncontradoException("Não encontrado.")).when(service).excluir(404);
    return new EpiEntregaController(service);
  }
  String endpoint() { return "/api/entregas-epis"; }
  String payload() { return "{\"colaboradorId\": 1, \"epiId\": 7, \"quantidade\": 2, \"dataEntrega\": \"2026-06-01\", \"assinatura\": \"Ana Ribeiro\"}"; }
  void conflict() { when(service.registrar(any())).thenThrow(new ConflitoException("Estoque insuficiente para esta entrega. Disponível: 0.")); }

  @org.junit.jupiter.api.Test void estoqueInsuficienteRetorna409ComODisponivel() throws Exception {
    when(service.registrar(any())).thenThrow(new ConflitoException("Estoque insuficiente para esta entrega. Disponível: 1."));

    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload()))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isConflict())
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath("$.mensagem")
        .value("Estoque insuficiente para esta entrega. Disponível: 1."));
  }

  @org.junit.jupiter.api.Test void listaFiltraPeloColaboradorInformado() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get(endpoint())
      .param("colaboradorId", "1"))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isOk())
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath("$[0].colaboradorId").value(1));

    verify(service).listar(1);
  }

  @org.junit.jupiter.api.Test void quantidadeNaoPositivaRetorna400() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload().replace("\"quantidade\": 2", "\"quantidade\": 0")))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }
}
