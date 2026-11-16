package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.ColaboradorRequest;
import br.com.senac.sgsst.dto.EpiRequest;
import br.com.senac.sgsst.dto.ImportacaoErroResponse;
import br.com.senac.sgsst.dto.TreinamentoRequest;
import br.com.senac.sgsst.exception.ConflitoException;
import br.com.senac.sgsst.exception.RequisicaoInvalidaException;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

class ImportacaoServiceTest {

  static final ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
  static final Validator validator = factory.getValidator();

  final ColaboradorService colaboradorService = mock(ColaboradorService.class);
  final TreinamentoService treinamentoService = mock(TreinamentoService.class);
  final EpiService epiService = mock(EpiService.class);
  final ImportacaoService service = new ImportacaoService(
    colaboradorService,
    treinamentoService,
    epiService,
    validator
  );

  @AfterAll static void close() { factory.close(); }

  private ColaboradorRequest colaborador(String matricula, String cpf, String email) {
    return new ColaboradorRequest(
      matricula, "Ana Silva", cpf, email, "Analista", "Produção", "Ativo"
    );
  }

  private TreinamentoRequest treinamento(String codigo, int validadeMeses) {
    return new TreinamentoRequest(
      codigo, "NR-35 Trabalho em Altura", "Norma Regulamentadora",
      "NR-35", "8", validadeMeses, "Ativo"
    );
  }

  private EpiRequest epi(String ca, LocalDate inclusao, LocalDate validade) {
    return new EpiRequest("Capacete", ca, inclusao, validade, 10);
  }

  @Test void loteMistoImportaValidasEReportaInvalidaNaLinhaCerta() {
    var primeira = colaborador("M01", "12345678901", "ana@example.test");
    var invalida = new ColaboradorRequest(
      "M02", "Ana", "abc", "invalido", "Analista", "Produção", "Ativo"
    );
    var terceira = colaborador("M03", "98765432100", "carla@example.test");

    var resultado = service.importarColaboradores(
      List.of(primeira, invalida, terceira)
    );

    assertEquals(3, resultado.total());
    assertEquals(2, resultado.importados());
    assertEquals(1, resultado.ignorados());
    assertEquals(1, resultado.erros().size());
    assertEquals(3, resultado.erros().get(0).linha());
    assertTrue(
      resultado.erros().get(0).mensagem().contains("11 dígitos"),
      "mensagem deve trazer a regra de CPF: "
        + resultado.erros().get(0).mensagem()
    );
    verify(colaboradorService, times(2)).criar(any());
  }

  @Test void duplicidadeViraErroDaLinhaESobraContinuaImportando() {
    var duplicada = colaborador("M02", "12345678901", "bia@example.test");
    var seguinte = colaborador("M03", "98765432100", "carla@example.test");

    doThrow(new ConflitoException("Já existe um colaborador com esta matrícula."))
      .when(colaboradorService).criar(duplicada);

    var resultado = service.importarColaboradores(List.of(duplicada, seguinte));

    assertEquals(2, resultado.total());
    assertEquals(1, resultado.importados());
    assertEquals(1, resultado.ignorados());
    assertEquals(1, resultado.erros().size());
    assertEquals(2, resultado.erros().get(0).linha());
    assertEquals(
      "Já existe um colaborador com esta matrícula.",
      resultado.erros().get(0).mensagem()
    );
  }

  @Test void requisicaoInvalidaDaRegraDeNegocioViraErroDaLinha() {
    var linha = colaborador("M01", "12345678901", "ana@example.test");

    doThrow(new RequisicaoInvalidaException("Regra de negócio impediu a gravação."))
      .when(colaboradorService).criar(linha);

    var resultado = service.importarColaboradores(List.of(linha));

    assertEquals(0, resultado.importados());
    assertEquals(1, resultado.erros().size());
    assertEquals(2, resultado.erros().get(0).linha());
    assertEquals(
      "Regra de negócio impediu a gravação.",
      resultado.erros().get(0).mensagem()
    );
  }

  @Test void loteSomenteInvalidoZeraImportadosEListaErros() {
    var semNada = new ColaboradorRequest(
      null, null, null, null, null, null, null
    );
    var invalida = new ColaboradorRequest(
      "M02", "Ana", "abc", "invalido", "Analista", "Produção", "Ativo"
    );

    var resultado = service.importarColaboradores(List.of(semNada, invalida));

    assertEquals(2, resultado.total());
    assertEquals(0, resultado.importados());
    assertEquals(2, resultado.ignorados());
    assertEquals(2, resultado.erros().size());
    assertEquals(
      List.of(2, 3),
      resultado.erros().stream().map(ImportacaoErroResponse::linha).toList()
    );
    verify(colaboradorService, never()).criar(any());
  }

  @Test void importaTreinamentosValidos() {
    var resultado = service.importarTreinamentos(
      List.of(treinamento("T01", 24), treinamento("T02", 0))
    );

    assertEquals(2, resultado.total());
    assertEquals(2, resultado.importados());
    assertEquals(0, resultado.ignorados());
    assertTrue(resultado.erros().isEmpty());
    verify(treinamentoService, times(2)).criar(any());
  }

  @Test void treinamentoInvalidoReportaLinhaEPreservaOsDemais() {
    var valido = treinamento("T01", 24);
    var invalido = new TreinamentoRequest(
      "T02", "Curso", "Geral", null, "8", -1, "Ativo"
    );
    var outroValido = treinamento("T03", 12);

    var resultado = service.importarTreinamentos(
      List.of(valido, invalido, outroValido)
    );

    assertEquals(2, resultado.importados());
    assertEquals(1, resultado.erros().size());
    assertEquals(3, resultado.erros().get(0).linha());
  }

  @Test void importaEpisValidos() {
    var resultado = service.importarEpis(
      List.of(
        epi("123", LocalDate.of(2026, 1, 1), LocalDate.of(2027, 1, 1)),
        epi("456", LocalDate.of(2026, 2, 1), LocalDate.of(2026, 2, 1))
      )
    );

    assertEquals(2, resultado.importados());
    assertTrue(resultado.erros().isEmpty());
    verify(epiService, times(2)).criar(any());
  }

  @Test void epiComValidadeAnteriorAInclusaoViraErroDaLinha() {
    var valido = epi("123", LocalDate.of(2026, 1, 1), LocalDate.of(2027, 1, 1));
    var invertido = epi(
      "456", LocalDate.of(2026, 1, 10), LocalDate.of(2026, 1, 1)
    );

    var resultado = service.importarEpis(List.of(valido, invertido));

    assertEquals(1, resultado.importados());
    assertEquals(1, resultado.erros().size());
    assertEquals(3, resultado.erros().get(0).linha());
    assertTrue(resultado.erros().get(0).mensagem().contains("inclusão"));
  }

  @Test void loteVazioOuNuloDevolveResumoZerado() {
    var vazio = service.importarColaboradores(List.of());
    var nulo = service.importarEpis(null);

    assertEquals(0, vazio.total());
    assertEquals(0, vazio.importados());
    assertEquals(0, vazio.erros().size());
    assertEquals(0, nulo.total());
    assertEquals(0, nulo.ignorados());
  }

  @Test void linhaNulaNoLoteViraErroDaLinha() {
    var resultado = service.importarTreinamentos(
      Arrays.asList(treinamento("T01", 24), null)
    );

    assertEquals(2, resultado.total());
    assertEquals(1, resultado.importados());
    assertEquals(1, resultado.erros().size());
    assertEquals(3, resultado.erros().get(0).linha());
    assertEquals("Linha vazia.", resultado.erros().get(0).mensagem());
  }
}
