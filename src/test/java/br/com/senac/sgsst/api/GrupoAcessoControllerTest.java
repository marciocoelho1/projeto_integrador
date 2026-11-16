package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.GrupoResponse;
import br.com.senac.sgsst.service.GrupoAcessoService;
import static org.mockito.Mockito.*;

class GrupoAcessoControllerTest extends CrudControllerContractTest {
  GrupoAcessoService service;

  Object controller() {
    service = mock(GrupoAcessoService.class);
    var response = new GrupoResponse(1, "Colaborador", "Foco em EPIs", java.util.List.of("sgst_epis"));
    when(service.listar()).thenReturn(java.util.List.of(response));
    when(service.buscarPorId(1)).thenReturn(response);
    when(service.criar(any())).thenReturn(response);
    when(service.atualizar(eq(1), any())).thenReturn(response);
    when(service.buscarPorId(404)).thenThrow(new br.com.senac.sgsst.exception.RecursoNaoEncontradoException("Não encontrado."));
    when(service.atualizar(eq(404), any())).thenThrow(new br.com.senac.sgsst.exception.RecursoNaoEncontradoException("Não encontrado."));
    when(service.definirModulos(eq(1), any())).thenReturn(response);
    when(service.definirModulos(eq(404), any())).thenThrow(new br.com.senac.sgsst.exception.RecursoNaoEncontradoException("Não encontrado."));
    doThrow(new br.com.senac.sgsst.exception.RecursoNaoEncontradoException("Não encontrado.")).when(service).excluir(404);
    return new GrupoAcessoController(service);
  }

  String endpoint() { return "/api/grupos"; }

  String payload() {
    return "{\"nomenclatura\": \"Colaborador\", \"finalidade\": \"Foco em EPIs\", \"modulos\": [\"sgst_epis\"]}";
  }

  void conflict() {
    when(service.criar(any())).thenThrow(new org.springframework.dao.DataIntegrityViolationException("test"));
  }

  @org.junit.jupiter.api.Test void matrizDeAcessosRespondeComModulos() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put(endpoint() + "/1/modulos")
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content("{\"modulos\": [\"sgst_epis\"]}"))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isOk())
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath("$.modulos[0]")
        .value("sgst_epis"));

    verify(service).definirModulos(1, java.util.List.of("sgst_epis"));
  }

  @org.junit.jupiter.api.Test void matrizDeGrupoInexistenteRetorna404() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put(endpoint() + "/404/modulos")
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content("{\"modulos\": []}"))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isNotFound());
  }
}
