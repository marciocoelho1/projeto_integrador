package br.com.senac.sgsst.api;
import br.com.senac.sgsst.dto.*;
import br.com.senac.sgsst.service.TurmaReciclagemService;
import br.com.senac.sgsst.exception.*;
import java.time.LocalDate;
import java.util.List;
import static org.mockito.Mockito.*;
class TurmaReciclagemControllerTest extends CrudControllerContractTest {
  TurmaReciclagemService service;
  Object controller() {
    service = mock(TurmaReciclagemService.class);
    var response = new TurmaReciclagemResponse(1, 2, "NR-35 Trabalho em Altura", "João Instrutor",
      LocalDate.of(2026, 5, 20), 20, "Agendada");
    when(service.listar(any())).thenReturn(List.of(response));
    when(service.buscarPorId(1)).thenReturn(response);
    when(service.criar(any())).thenReturn(response);
    when(service.atualizar(eq(1), any())).thenReturn(response);
    when(service.buscarPorId(404)).thenThrow(new RecursoNaoEncontradoException("Não encontrado."));
    when(service.atualizar(eq(404), any())).thenThrow(new RecursoNaoEncontradoException("Não encontrado."));
    doThrow(new RecursoNaoEncontradoException("Não encontrado.")).when(service).excluir(404);
    return new TurmaReciclagemController(service);
  }
  String endpoint() { return "/api/turmas-reciclagem"; }
  String payload() { return "{\"treinamentoId\": 2, \"instrutor\": \"João Instrutor\", \"dataAgendada\": \"2026-05-20\", \"vagas\": 20, \"status\": \"Agendada\"}"; }
  void conflict() { when(service.criar(any())).thenThrow(new org.springframework.dao.DataIntegrityViolationException("test")); }
  @org.junit.jupiter.api.Test void listaFiltraPorTreinamento() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get(endpoint()).param("treinamentoId", "2"))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isOk());
    verify(service).listar(2);
  }
  @org.junit.jupiter.api.Test void vagasNegativasRetornam400() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload().replace("\"vagas\": 20", "\"vagas\": -1")))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }
  @org.junit.jupiter.api.Test void statusForaDaListaRetorna400() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload().replace("\"Agendada\"", "\"Inscrições Abertas\"")))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }
  @org.junit.jupiter.api.Test void zeroVagasEAceito() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put(endpoint() + "/1")
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload().replace("\"vagas\": 20", "\"vagas\": 0")))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isOk());
  }
  @org.junit.jupiter.api.Test void treinamentoInexistenteRetorna400() throws Exception {
    when(service.criar(any())).thenThrow(new RequisicaoInvalidaException("Treinamento informado não existe."));
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload()))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }
}
