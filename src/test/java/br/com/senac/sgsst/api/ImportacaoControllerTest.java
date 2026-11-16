package br.com.senac.sgsst.api;

import br.com.senac.sgsst.dto.ColaboradorRequest;
import br.com.senac.sgsst.exception.ApiExceptionHandler;
import br.com.senac.sgsst.exception.ConflitoException;
import br.com.senac.sgsst.service.ColaboradorService;
import br.com.senac.sgsst.service.EpiService;
import br.com.senac.sgsst.service.ImportacaoService;
import br.com.senac.sgsst.service.TreinamentoService;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Exercita o controller sobre o serviço real (bean validation + linhas
 * independentes) com os serviços de domínio mockados.
 */
class ImportacaoControllerTest {

  static final ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
  static final Validator validator = factory.getValidator();

  ColaboradorService colaboradorService;
  TreinamentoService treinamentoService;
  EpiService epiService;
  MockMvc mvc;

  @BeforeEach void setup() {
    colaboradorService = mock(ColaboradorService.class);
    treinamentoService = mock(TreinamentoService.class);
    epiService = mock(EpiService.class);

    var importacao = new ImportacaoService(
      colaboradorService,
      treinamentoService,
      epiService,
      validator
    );

    mvc = MockMvcBuilders
      .standaloneSetup(new ImportacaoController(importacao))
      .setControllerAdvice(new ApiExceptionHandler())
      .build();
  }

  @AfterAll static void close() { factory.close(); }

  private String colaboradorJson(String matricula, String cpf, String email) {
    return "{"
      + "\"matricula\":\"" + matricula + "\","
      + "\"nome\":\"Ana Silva\","
      + "\"cpf\":\"" + cpf + "\","
      + "\"email\":\"" + email + "\","
      + "\"cargo\":\"Analista\","
      + "\"setor\":\"Producao\","
      + "\"status\":\"Ativo\""
      + "}";
  }

  private String lote(String... linhas) {
    return "{\"linhas\":[" + String.join(",", linhas) + "]}";
  }

  private String postar(String recurso, String corpo) throws Exception {
    return mvc.perform(
        post("/api/importacao/" + recurso)
          .contentType(MediaType.APPLICATION_JSON)
          .content(corpo)
      )
      .andReturn()
      .getResponse()
      .getContentAsString();
  }

  @Test void loteMistoImportaLinhasValidasEReportaInvalidaNaLinhaCerta()
    throws Exception {
    String corpo = lote(
      colaboradorJson("M01", "12345678901", "ana@example.test"),
      colaboradorJson("M02", "abc", "invalido"),
      colaboradorJson("M03", "98765432100", "carla@example.test")
    );

    mvc.perform(
        post("/api/importacao/colaboradores")
          .contentType(MediaType.APPLICATION_JSON)
          .content(corpo)
      )
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.total").value(3))
      .andExpect(jsonPath("$.importados").value(2))
      .andExpect(jsonPath("$.ignorados").value(1))
      .andExpect(jsonPath("$.erros.length()").value(1))
      .andExpect(jsonPath("$.erros[0].linha").value(3))
      .andExpect(jsonPath("$.erros[0].mensagem").isNotEmpty());

    verify(colaboradorService, times(2)).criar(any());
  }

  @Test void duplicidadeDoServicoViraErroDaLinhaENaoErroDoLote()
    throws Exception {
    var duplicada = new ColaboradorRequest(
      "M02", "Ana Silva", "12345678901", "bia@example.test",
      "Analista", "Producao", "Ativo"
    );

    doThrow(new ConflitoException("Já existe um colaborador com esta matrícula."))
      .when(colaboradorService).criar(duplicada);

    String corpo = lote(
      colaboradorJson("M02", "12345678901", "bia@example.test"),
      colaboradorJson("M03", "98765432100", "carla@example.test")
    );

    mvc.perform(
        post("/api/importacao/colaboradores")
          .contentType(MediaType.APPLICATION_JSON)
          .content(corpo)
      )
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.total").value(2))
      .andExpect(jsonPath("$.importados").value(1))
      .andExpect(jsonPath("$.ignorados").value(1))
      .andExpect(jsonPath("$.erros.length()").value(1))
      .andExpect(jsonPath("$.erros[0].linha").value(2))
      .andExpect(jsonPath("$.erros[0].mensagem")
        .value("Já existe um colaborador com esta matrícula."));
  }

  @Test void loteSomenteInvalidoRetorna200ComImportadosZeroEImportadosVazios()
    throws Exception {
    String corpo = lote(
      colaboradorJson("", "abc", "invalido"),
      colaboradorJson("M02", "123", "tambem-invalido")
    );

    mvc.perform(
        post("/api/importacao/colaboradores")
          .contentType(MediaType.APPLICATION_JSON)
          .content(corpo)
      )
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.total").value(2))
      .andExpect(jsonPath("$.importados").value(0))
      .andExpect(jsonPath("$.ignorados").value(2))
      .andExpect(jsonPath("$.erros.length()").value(2))
      .andExpect(jsonPath("$.erros[0].linha").value(2))
      .andExpect(jsonPath("$.erros[1].linha").value(3));
  }

  @Test void loteAcimaDe500LinhasRetorna400() throws Exception {
    StringBuilder corpo = new StringBuilder("{\"linhas\":[");

    for (int indice = 0; indice < 501; indice++) {
      if (indice > 0) {
        corpo.append(',');
      }
      corpo.append(colaboradorJson(
        "M" + indice, "12345678901", "pessoa" + indice + "@example.test"
      ));
    }

    corpo.append("]}");

    mvc.perform(
        post("/api/importacao/colaboradores")
          .contentType(MediaType.APPLICATION_JSON)
          .content(corpo.toString())
      )
      .andExpect(status().isBadRequest())
      .andExpect(jsonPath("$.mensagem").exists());
  }

  @Test void exatamente500LinhasContinuaAceito() throws Exception {
    StringBuilder corpo = new StringBuilder("{\"linhas\":[");

    for (int indice = 0; indice < 500; indice++) {
      if (indice > 0) {
        corpo.append(',');
      }
      corpo.append(colaboradorJson(
        "M" + indice, "12345678901", "pessoa" + indice + "@example.test"
      ));
    }

    corpo.append("]}");

    mvc.perform(
        post("/api/importacao/colaboradores")
          .contentType(MediaType.APPLICATION_JSON)
          .content(corpo.toString())
      )
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.total").value(500))
      .andExpect(jsonPath("$.importados").value(500));
  }

  @Test void corpoVazioRetorna400() throws Exception {
    mvc.perform(
        post("/api/importacao/colaboradores")
          .contentType(MediaType.APPLICATION_JSON)
          .content("")
      )
      .andExpect(status().isBadRequest());
  }

  @Test void loteSemLinhasRetorna400() throws Exception {
    mvc.perform(
        post("/api/importacao/colaboradores")
          .contentType(MediaType.APPLICATION_JSON)
          .content("{}")
      )
      .andExpect(status().isBadRequest())
      .andExpect(jsonPath("$.detalhes").isArray());

    mvc.perform(
        post("/api/importacao/colaboradores")
          .contentType(MediaType.APPLICATION_JSON)
          .content("{\"linhas\":[]}")
      )
      .andExpect(status().isBadRequest())
      .andExpect(jsonPath("$.detalhes").isArray());
  }

  @Test void jsonInvalidoRetorna400() throws Exception {
    mvc.perform(
        post("/api/importacao/colaboradores")
          .contentType(MediaType.APPLICATION_JSON)
          .content("{")
      )
      .andExpect(status().isBadRequest());
  }

  @Test void importaTreinamentosComSucesso() throws Exception {
    String corpo = "{\"linhas\":["
      + "{\"codigo\":\"T01\",\"nome\":\"NR-35\",\"classificacao\":\"NR\","
      + "\"nr\":\"NR-35\",\"cargaHoraria\":\"8\",\"validadeMeses\":24,"
      + "\"status\":\"Ativo\"},"
      + "{\"codigo\":\"T02\",\"nome\":\"Brigada\",\"classificacao\":\"Geral\","
      + "\"nr\":null,\"cargaHoraria\":\"4\",\"validadeMeses\":null,"
      + "\"status\":\"Inativo\"}"
      + "]}";

    mvc.perform(
        post("/api/importacao/treinamentos")
          .contentType(MediaType.APPLICATION_JSON)
          .content(corpo)
      )
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.importados").value(2))
      .andExpect(jsonPath("$.erros.length()").value(0));

    verify(treinamentoService, times(2)).criar(any());
  }

  @Test void treinamentoInvalidoNaoDerrubaLote() throws Exception {
    String corpo = "{\"linhas\":["
      + "{\"codigo\":\"T01\",\"nome\":\"NR-35\",\"classificacao\":\"NR\","
      + "\"nr\":\"NR-35\",\"cargaHoraria\":\"8\",\"validadeMeses\":24,"
      + "\"status\":\"Ativo\"},"
      + "{\"codigo\":\"\",\"nome\":\"\",\"classificacao\":\"\","
      + "\"cargaHoraria\":\"\",\"status\":\"Errado\"}"
      + "]}";

    mvc.perform(
        post("/api/importacao/treinamentos")
          .contentType(MediaType.APPLICATION_JSON)
          .content(corpo)
      )
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.importados").value(1))
      .andExpect(jsonPath("$.erros[0].linha").value(3));
  }

  @Test void importaEpisComSucesso() throws Exception {
    String corpo = "{\"linhas\":["
      + "{\"descricao\":\"Capacete\",\"ca\":\"12345\","
      + "\"inclusao\":\"2026-01-01\",\"validade\":\"2027-01-01\","
      + "\"quantidade\":10},"
      + "{\"descricao\":\"Luva\",\"ca\":\"54321\","
      + "\"inclusao\":\"2026-02-01\",\"validade\":\"2026-02-01\","
      + "\"quantidade\":0}"
      + "]}";

    mvc.perform(
        post("/api/importacao/epis")
          .contentType(MediaType.APPLICATION_JSON)
          .content(corpo)
      )
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.importados").value(2));

    verify(epiService, times(2)).criar(any());
  }

  @Test void epiComDataInvalidaViraErroDaLinha() throws Exception {
    String corpo = "{\"linhas\":["
      + "{\"descricao\":\"Capacete\",\"ca\":\"12345\","
      + "\"inclusao\":\"2026-01-01\",\"validade\":\"2027-01-01\","
      + "\"quantidade\":10},"
      + "{\"descricao\":\"Luva\",\"ca\":\"54321\","
      + "\"inclusao\":\"2026-02-01\",\"validade\":\"2026-01-01\","
      + "\"quantidade\":1}"
      + "]}";

    mvc.perform(
        post("/api/importacao/epis")
          .contentType(MediaType.APPLICATION_JSON)
          .content(corpo)
      )
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.importados").value(1))
      .andExpect(jsonPath("$.erros[0].linha").value(3));
  }

  @Test void resumoDoLoteVazioDeTreinamentoNaoQuebra() throws Exception {
    String resposta = postar(
      "treinamentos",
      "{\"linhas\":[{\"codigo\":\"T01\",\"nome\":\"Curso\","
        + "\"classificacao\":\"Geral\",\"cargaHoraria\":\"8\","
        + "\"status\":\"Ativo\"}]}"
    );

    org.junit.jupiter.api.Assertions.assertTrue(
      resposta.contains("\"importados\":1"),
      resposta
    );
  }
}
