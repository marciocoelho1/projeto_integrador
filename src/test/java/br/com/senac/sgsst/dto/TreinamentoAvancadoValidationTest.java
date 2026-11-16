package br.com.senac.sgsst.dto;

import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Test;
import java.time.LocalDate;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

/** Bean Validation dos itens 5 e 6 (vínculos, certificações, cargos/LNT e turmas de reciclagem). */
class TreinamentoAvancadoValidationTest {
  static final ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
  static final Validator validator = factory.getValidator();
  static final LocalDate date = LocalDate.of(2026, 1, 1);
  @AfterAll static void close() { factory.close(); }

  @Test void vinculoNormalizaEspacosEAceitaOsTresStatus() {
    for (var status : List.of("Concluído", "Em Andamento", "Pendente")) {
      var request = new ColaboradorTreinamentoRequest(1, 2, date, "  " + status + "  ");
      assertTrue(validator.validate(request).isEmpty());
      assertEquals(status, request.status());
    }
  }

  @Test void vinculoAceitaDataDeConclusaoNula() {
    var request = new ColaboradorTreinamentoRequest(1, 2, null, "Pendente");
    assertTrue(validator.validate(request).isEmpty());
    assertNull(request.dataConclusao());
  }

  @Test void vinculoRejeitaIdsNulosStatusVazioEStatusForaDaLista() {
    assertEquals(2, validator.validate(new ColaboradorTreinamentoRequest(null, null, null, "Pendente")).size());
    assertEquals(1, validator.validate(new ColaboradorTreinamentoRequest(1, 2, date, "Cancelado")).size());
    assertEquals(2, validator.validate(new ColaboradorTreinamentoRequest(1, 2, date, " ")).size());
  }

  @Test void certificacaoRejeitaValidadeAnteriorAEmissao() {
    var request = new CertificacaoRequest(1, 2, "SENAC", "8 horas", date, date.minusDays(1), null);
    var violacoes = validator.validate(request);
    assertEquals(1, violacoes.size());
    assertEquals("validadePosteriorAEmissao", violacoes.iterator().next().getPropertyPath().toString());
    assertTrue(validator.validate(new CertificacaoRequest(1, 2, "SENAC", "8 horas", date, date, null)).isEmpty());
  }

  @Test void certificacaoNormalizaTextoEArquivoEmBranco() {
    var request = new CertificacaoRequest(1, 2, "  SENAC  ", " 8 horas ", date, date, "   ");
    assertTrue(validator.validate(request).isEmpty());
    assertEquals("SENAC", request.instituicao());
    assertEquals("8 horas", request.cargaHoraria());
    assertNull(request.arquivoUrl());
  }

  @Test void certificacaoRejeitaCamposObrigatoriosEmBranco() {
    var request = new CertificacaoRequest(null, null, " ", " ", null, null, null);
    assertEquals(6, validator.validate(request).size());
  }

  @Test void cargoRejeitaStatusForaDaListaETextosEmBranco() {
    assertTrue(validator.validate(new CargoRequest("Operador de Caixa", "Frente de Loja", "Ativo")).isEmpty());
    assertEquals(1, validator.validate(new CargoRequest("Operador de Caixa", "Frente de Loja", "Afastado")).size());
    assertEquals(4, validator.validate(new CargoRequest(" ", " ", " ")).size());
  }

  @Test void matrizDoCargoRejeitaListaNulaOuItemSemTreinamento() {
    assertEquals(1, validator.validate(new CargoTreinamentosRequest(null)).size());
    assertEquals(1, validator.validate(new CargoTreinamentosRequest(List.of(new CargoTreinamentoItemRequest(null, true)))).size());
    assertTrue(validator.validate(new CargoTreinamentosRequest(List.of(new CargoTreinamentoItemRequest(2, null)))).isEmpty());
  }

  @Test void matrizAssumeObrigatorioVerdadeiroQuandoNaoInformado() {
    assertTrue(new CargoTreinamentoItemRequest(2, null).obrigatorioEfetivo());
    assertFalse(new CargoTreinamentoItemRequest(2, false).obrigatorioEfetivo());
  }

  @Test void turmaRejeitaVagasNegativasStatusForaDaListaECamposVazios() {
    assertEquals(1, validator.validate(new TurmaReciclagemRequest(2, "Instrutor", date, -1, "Agendada")).size());
    assertEquals(1, validator.validate(new TurmaReciclagemRequest(2, "Instrutor", date, 0, "Planejada")).size());
    assertEquals(6, validator.validate(new TurmaReciclagemRequest(null, " ", null, null, " ")).size());
    assertTrue(validator.validate(new TurmaReciclagemRequest(2, " Instrutor ", date, 0, "Concluída")).isEmpty());
  }
}
