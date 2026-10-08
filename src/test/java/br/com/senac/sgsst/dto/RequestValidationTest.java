package br.com.senac.sgsst.dto;

import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Test;
import java.time.LocalDate;
import static org.junit.jupiter.api.Assertions.*;

class RequestValidationTest {
  static final ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
  static final Validator validator = factory.getValidator();
  static final LocalDate date = LocalDate.of(2026, 1, 1);
  @AfterAll static void close() { factory.close(); }
  @Test void colaboradorValidoNormalizaEspacosECpfFormatado() {
    var request = new ColaboradorRequest(" M01 ", " Ana ", "123.456.789-01", " ana@example.test ", " Técnica ", " Produção ", " Ativo ");
    assertTrue(validator.validate(request).isEmpty());
    assertEquals("M01", request.matricula());
    assertEquals("12345678901", request.cpf());
    assertEquals("Ana", request.nome());
    assertEquals("ana@example.test", request.email());
  }
  @Test void colaboradorRejeitaVaziosStatusCpfEmailETamanho() {
    var request = new ColaboradorRequest(" ", "a".repeat(151), "abc", "invalido", " ", " ", "Inválido");
    assertEquals(7, validator.validate(request).stream().map(v -> v.getPropertyPath().toString()).distinct().count());
  }
  @Test void treinamentoValidoComNrEValidadeNulos() {
    var request = new TreinamentoRequest(" T01 ", " Segurança ", " Obrigatório ", null, " 8 horas ", null, " Ativo ");
    assertTrue(validator.validate(request).isEmpty());
    assertEquals("T01", request.codigo());
    assertEquals("8 horas", request.cargaHoraria());
  }
  @Test void treinamentoRejeitaNegativoStatusETamanhos() {
    var request = new TreinamentoRequest("a".repeat(31), "a".repeat(181), "a".repeat(61), "a".repeat(61), "a".repeat(31), -1, "Afastado");
    assertEquals(7, validator.validate(request).size());
  }
  @Test void treinamentoAceitaValidadeZero() {
    assertTrue(validator.validate(new TreinamentoRequest("T01", "Segurança", "Obrigatório", "NR-10", "8 horas", 0, "Inativo")).isEmpty());
  }
  @Test void epiValidoComQuantidadeZero() {
    var request = new EpiRequest(" Capacete ", " 123 ", date, date, 0);
    assertTrue(validator.validate(request).isEmpty());
    assertEquals("Capacete", request.descricao()); assertEquals("123", request.ca());
  }
  @Test void epiRejeitaDatasNulasQuantidadeNegativaETamanhos() {
    var request = new EpiRequest("a".repeat(181), "a".repeat(31), null, null, -1);
    assertEquals(5, validator.validate(request).size());
  }
  @Test void epiRejeitaQuantidadeNula() {
    assertFalse(validator.validate(new EpiRequest("Capacete", "123", date, date, null)).isEmpty());
  }
}
