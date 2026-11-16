package br.com.senac.sgsst.api;
import br.com.senac.sgsst.dto.*;
import br.com.senac.sgsst.service.CargoService;
import br.com.senac.sgsst.exception.*;
import java.util.List;
import static org.mockito.Mockito.*;
class CargoControllerTest extends CrudControllerContractTest {
  CargoService service;
  Object controller() {
    service = mock(CargoService.class);
    var response = new CargoResponse(1, "Operador de Empilhadeira", "Estoque / Logística", "Ativo");
    when(service.listar()).thenReturn(List.of(response));
    when(service.buscarPorId(1)).thenReturn(response);
    when(service.criar(any())).thenReturn(response);
    when(service.atualizar(eq(1), any())).thenReturn(response);
    when(service.buscarPorId(404)).thenThrow(new RecursoNaoEncontradoException("Não encontrado."));
    when(service.atualizar(eq(404), any())).thenThrow(new RecursoNaoEncontradoException("Não encontrado."));
    doThrow(new RecursoNaoEncontradoException("Não encontrado.")).when(service).excluir(404);
    return new CargoController(service);
  }
  String endpoint() { return "/api/cargos"; }
  String payload() { return "{\"nome\": \"Operador de Empilhadeira\", \"setor\": \"Estoque / Logística\", \"status\": \"Ativo\"}"; }
  void conflict() { when(service.criar(any())).thenThrow(new org.springframework.dao.DataIntegrityViolationException("test")); }
  @org.junit.jupiter.api.Test void statusForaDaListaRetorna400() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload().replace("\"Ativo\"", "\"Afastado\"")))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }
  @org.junit.jupiter.api.Test void substituiMatrizDeTreinamentosDoCargo() throws Exception {
    when(service.substituirMatriz(eq(1), any())).thenReturn(new LntResponse(1, "Operador de Empilhadeira", "Estoque / Logística", "Ativo",
      List.of(new CargoTreinamentoResponse(1, 2, "NR-11 Operação Segura de Empilhadeira", "NR-11", true))));
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put(endpoint() + "/1/treinamentos")
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content("{\"treinamentos\": [{\"treinamentoId\": 2, \"obrigatorio\": true}]}"))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isOk())
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath("$.treinamentos[0].treinamentoId").value(2))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath("$.cargo").value("Operador de Empilhadeira"));
  }
  @org.junit.jupiter.api.Test void matrizSemListaRetorna400() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put(endpoint() + "/1/treinamentos")
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content("{}"))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }
  @org.junit.jupiter.api.Test void matrizComTreinamentoNuloRetorna400() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put(endpoint() + "/1/treinamentos")
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content("{\"treinamentos\": [{\"obrigatorio\": true}]}"))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }
  @org.junit.jupiter.api.Test void matrizComTreinamentoInexistenteRetorna400() throws Exception {
    when(service.substituirMatriz(eq(1), any())).thenThrow(new RequisicaoInvalidaException("Treinamento informado não existe: 99"));
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put(endpoint() + "/1/treinamentos")
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content("{\"treinamentos\": [{\"treinamentoId\": 99, \"obrigatorio\": true}]}"))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }
  @org.junit.jupiter.api.Test void matrizDeCargoInexistenteRetorna404() throws Exception {
    when(service.substituirMatriz(eq(404), any())).thenThrow(new RecursoNaoEncontradoException("Cargo não encontrado."));
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put(endpoint() + "/404/treinamentos")
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content("{\"treinamentos\": [{\"treinamentoId\": 2}]}"))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isNotFound());
  }
}
