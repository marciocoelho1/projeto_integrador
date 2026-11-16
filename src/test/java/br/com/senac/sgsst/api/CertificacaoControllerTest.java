package br.com.senac.sgsst.api;
import br.com.senac.sgsst.dto.*;
import br.com.senac.sgsst.service.CertificacaoService;
import br.com.senac.sgsst.exception.*;
import java.time.LocalDate;
import java.util.List;
import static org.mockito.Mockito.*;
class CertificacaoControllerTest extends CrudControllerContractTest {
  CertificacaoService service;
  Object controller() {
    service = mock(CertificacaoService.class);
    var response = new CertificacaoResponse(1, 1, "Ana Paula Souza", "Operadora de Caixa", 2,
      "NR-35 Trabalho em Altura", "SENAC", "8 horas", LocalDate.of(2026, 1, 10), LocalDate.of(2027, 1, 10),
      "https://exemplo.test/certificado.pdf", "Ativa");
    when(service.listar(any())).thenReturn(List.of(response));
    when(service.buscarPorId(1)).thenReturn(response);
    when(service.criar(any())).thenReturn(response);
    when(service.atualizar(eq(1), any())).thenReturn(response);
    when(service.buscarPorId(404)).thenThrow(new RecursoNaoEncontradoException("Não encontrado."));
    when(service.atualizar(eq(404), any())).thenThrow(new RecursoNaoEncontradoException("Não encontrado."));
    doThrow(new RecursoNaoEncontradoException("Não encontrado.")).when(service).excluir(404);
    return new CertificacaoController(service);
  }
  String endpoint() { return "/api/certificacoes"; }
  String payload() {
    return "{\"colaboradorId\": 1, \"treinamentoId\": 2, \"instituicao\": \"SENAC\", \"cargaHoraria\": \"8 horas\", "
      + "\"emitidaEm\": \"2026-01-10\", \"validade\": \"2027-01-10\", \"arquivoUrl\": \"https://exemplo.test/certificado.pdf\"}";
  }
  void conflict() { when(service.criar(any())).thenThrow(new org.springframework.dao.DataIntegrityViolationException("test")); }
  @org.junit.jupiter.api.Test void listaFiltraPorColaborador() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get(endpoint()).param("colaboradorId", "7"))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isOk());
    verify(service).listar(7);
  }
  @org.junit.jupiter.api.Test void validadeAnteriorAEmissaoRetorna400() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload().replace("\"validade\": \"2027-01-10\"", "\"validade\": \"2025-12-31\"")))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }
  @org.junit.jupiter.api.Test void validadeIgualAEmissaoEAceita() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put(endpoint() + "/1")
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload().replace("\"validade\": \"2027-01-10\"", "\"validade\": \"2026-01-10\"")))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isOk());
  }
  @org.junit.jupiter.api.Test void certificacaoDuplicadaRetorna409() throws Exception {
    when(service.criar(any())).thenThrow(new ConflitoException("Já existe certificação deste treinamento para o colaborador com esta validade."));
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload()))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isConflict());
  }
  @org.junit.jupiter.api.Test void instituicaoLongaRetorna400() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload().replace("\"SENAC\"", "\"" + "a".repeat(151) + "\"")))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }
  @org.junit.jupiter.api.Test void dataInvalidaRetorna400() throws Exception {
    mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post(endpoint())
      .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
      .content(payload().replace("2026-01-10", "2026-02-30")))
      .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isBadRequest());
  }
}
