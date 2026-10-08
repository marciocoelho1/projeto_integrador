package br.com.senac.sgsst.api;
import br.com.senac.sgsst.dto.*;
import br.com.senac.sgsst.service.TreinamentoService;
import br.com.senac.sgsst.exception.*;
import static org.mockito.Mockito.*;
class TreinamentoControllerTest extends CrudControllerContractTest {
  TreinamentoService service;
  Object controller() {
    service = mock(TreinamentoService.class);
    var response = new TreinamentoResponse(1, "TR01", "Segurança", "Obrigatório", "NR-10", "8 horas", null, "Ativo");
    when(service.listar()).thenReturn(java.util.List.of(response));
    when(service.buscarPorId(1)).thenReturn(response);
    when(service.criar(any())).thenReturn(response);
    when(service.atualizar(eq(1), any())).thenReturn(response);
    when(service.buscarPorId(404)).thenThrow(new RecursoNaoEncontradoException("Não encontrado."));
    when(service.atualizar(eq(404), any())).thenThrow(new RecursoNaoEncontradoException("Não encontrado."));
    doThrow(new RecursoNaoEncontradoException("Não encontrado.")).when(service).excluir(404);
    return new TreinamentoController(service);
  }
  String endpoint() { return "/api/treinamentos"; }
  String payload() { return "{\"codigo\": \"TR01\", \"nome\": \"Segurança\", \"classificacao\": \"Obrigatório\", \"nr\": \"NR-10\", \"cargaHoraria\": \"8 horas\", \"validadeMeses\": null, \"status\": \"Ativo\"}"; }
  void conflict() { when(service.criar(any())).thenThrow(new org.springframework.dao.DataIntegrityViolationException("test")); }
  @org.junit.jupiter.api.Test void campoInvalidoRetorna400() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload().replace("\"validadeMeses\": null", "\"validadeMeses\": -1")))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }
}
