package br.com.senac.sgsst.api;
import br.com.senac.sgsst.dto.*;
import br.com.senac.sgsst.service.ColaboradorService;
import br.com.senac.sgsst.exception.*;
import static org.mockito.Mockito.*;
class ColaboradorControllerTest extends CrudControllerContractTest {
  ColaboradorService service;
  Object controller() {
    service = mock(ColaboradorService.class);
    var response = new ColaboradorResponse(1, "M01", "Ana", "12345678901", "ana@example.test", "Técnica", "Produção", "Ativo");
    when(service.listar()).thenReturn(java.util.List.of(response));
    when(service.buscarPorId(1)).thenReturn(response);
    when(service.criar(any())).thenReturn(response);
    when(service.atualizar(eq(1), any())).thenReturn(response);
    when(service.buscarPorId(404)).thenThrow(new RecursoNaoEncontradoException("Não encontrado."));
    when(service.atualizar(eq(404), any())).thenThrow(new RecursoNaoEncontradoException("Não encontrado."));
    doThrow(new RecursoNaoEncontradoException("Não encontrado.")).when(service).excluir(404);
    return new ColaboradorController(service);
  }
  String endpoint() { return "/api/colaboradores"; }
  String payload() { return "{\"matricula\": \"M01\", \"nome\": \"Ana\", \"cpf\": \"12345678901\", \"email\": \"ana@example.test\", \"cargo\": \"Técnica\", \"setor\": \"Produção\", \"status\": \"Ativo\"}"; }
  void conflict() { when(service.criar(any())).thenThrow(new org.springframework.dao.DataIntegrityViolationException("test")); }
  @org.junit.jupiter.api.Test void campoInvalidoRetorna400() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload().replace("\"email\": \"ana@example.test\"", "\"email\": \"invalido\"")))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }
}
