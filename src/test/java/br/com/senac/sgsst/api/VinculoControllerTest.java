package br.com.senac.sgsst.api;
import br.com.senac.sgsst.dto.*;
import br.com.senac.sgsst.service.ColaboradorTreinamentoService;
import br.com.senac.sgsst.exception.*;
import java.time.LocalDate;
import java.util.List;
import static org.mockito.Mockito.*;
class VinculoControllerTest extends CrudControllerContractTest {
  ColaboradorTreinamentoService service;
  Object controller() {
    service = mock(ColaboradorTreinamentoService.class);
    var response = new ColaboradorTreinamentoResponse(1, 1, "Ana Paula Souza", "Repositora", 2,
      "NR-06 Uso Adequado e Guarda de EPIs", LocalDate.of(2026, 3, 10), "Concluído", LocalDate.of(2027, 3, 10));
    when(service.listar(any())).thenReturn(List.of(response));
    when(service.buscarPorId(1)).thenReturn(response);
    when(service.criar(any())).thenReturn(response);
    when(service.atualizar(eq(1), any())).thenReturn(response);
    when(service.buscarPorId(404)).thenThrow(new RecursoNaoEncontradoException("Não encontrado."));
    when(service.atualizar(eq(404), any())).thenThrow(new RecursoNaoEncontradoException("Não encontrado."));
    doThrow(new RecursoNaoEncontradoException("Não encontrado.")).when(service).excluir(404);
    return new ColaboradorTreinamentoController(service);
  }
  String endpoint() { return "/api/vinculos"; }
  String payload() { return "{\"colaboradorId\": 1, \"treinamentoId\": 2, \"dataConclusao\": \"2026-03-10\", \"status\": \"Concluído\"}"; }
  void conflict() { when(service.criar(any())).thenThrow(new org.springframework.dao.DataIntegrityViolationException("test")); }
  @org.junit.jupiter.api.Test void listaFiltraPorColaborador() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get(endpoint()).param("colaboradorId", "7"))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isOk());
    verify(service).listar(7);
  }
  @org.junit.jupiter.api.Test void statusForaDaListaRetorna400() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload().replace("\"Concluído\"", "\"Cancelado\"")))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }
  @org.junit.jupiter.api.Test void dataDeConclusaoNulaEAceita() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload().replace("\"2026-03-10\"", "null")))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isCreated());
  }
  @org.junit.jupiter.api.Test void vinculoDuplicadoRetorna409() throws Exception {
    when(service.criar(any())).thenThrow(new ConflitoException("Este colaborador já possui vínculo com este treinamento."));
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload()))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isConflict());
  }
  @org.junit.jupiter.api.Test void referenciaInexistenteRetorna400() throws Exception {
    when(service.criar(any())).thenThrow(new RequisicaoInvalidaException("Treinamento informado não existe."));
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload()))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }
}
