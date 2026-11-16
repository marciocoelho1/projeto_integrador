package br.com.senac.sgsst.api;
import br.com.senac.sgsst.dto.*;
import br.com.senac.sgsst.service.ChamadoService;
import br.com.senac.sgsst.exception.*;
import static org.mockito.Mockito.*;
class ChamadoControllerTest extends CrudControllerContractTest {
  ChamadoService service;
  Object controller() {
    service = mock(ChamadoService.class);
    var response = new ChamadoResponse(
      1, "Ajuda", "Dúvida sobre renovação", null, "Colaborador", "Em andamento",
      java.time.Instant.parse("2026-01-01T12:00:00Z"), null
    );
    when(service.listar(any(), anyBoolean())).thenReturn(java.util.List.of(response));
    when(service.buscarPorId(1)).thenReturn(response);
    when(service.criar(any())).thenReturn(response);
    when(service.atualizarStatus(eq(1), any())).thenReturn(response);
    when(service.buscarPorId(404)).thenThrow(new RecursoNaoEncontradoException("Não encontrado."));
    when(service.atualizarStatus(eq(404), any())).thenThrow(new RecursoNaoEncontradoException("Não encontrado."));
    doThrow(new RecursoNaoEncontradoException("Não encontrado.")).when(service).excluir(404);
    return new ChamadoController(service);
  }
  String endpoint() { return "/api/chamados"; }
  String payload() { return "{\"tipo\": \"Ajuda\", \"descricao\": \"Dúvida sobre renovação\", \"solicitante\": \"Colaborador\", \"status\": \"Em andamento\"}"; }
  void conflict() { when(service.criar(any())).thenThrow(new org.springframework.dao.DataIntegrityViolationException("test")); }

  @org.junit.jupiter.api.Test void listaMeusUsaParametroDaSessao() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get(endpoint())
      .param("meus", "true"))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isOk());

    verify(service).listar(null, true);
  }

  @org.junit.jupiter.api.Test void filtraPorStatus() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get(endpoint())
      .param("status", "Concluída"))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isOk());

    verify(service).listar("Concluída", false);
  }

  @org.junit.jupiter.api.Test void statusInvalidoNoCorpoRetorna400() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put(endpoint() + "/1")
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload().replace("Em andamento", "Pendente")))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }

  @org.junit.jupiter.api.Test void tipoForaDoPadraoRetorna400() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload().replace("\"Ajuda\"", "\"Reclamação\"")))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }
}
