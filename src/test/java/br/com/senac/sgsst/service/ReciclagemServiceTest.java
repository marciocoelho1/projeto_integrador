package br.com.senac.sgsst.service;
import br.com.senac.sgsst.dto.*;
import br.com.senac.sgsst.entity.*;
import br.com.senac.sgsst.repository.*;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import java.time.LocalDate;
import java.util.*;
import org.springframework.data.domain.Sort;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
class ReciclagemServiceTest {
  final ColaboradorTreinamentoRepository repository = mock(ColaboradorTreinamentoRepository.class);
  final ReciclagemService service = new ReciclagemService(repository);
  final LocalDate hoje = LocalDate.of(2026, 6, 1);

  static Colaborador colaborador() {
    var entity = new Colaborador();
    ReflectionTestUtils.setField(entity, "id", 1);
    entity.setMatricula("M01");
    entity.setNome("Carlos Eduardo Silva");
    entity.setCpf("12345678901");
    entity.setEmail("carlos@example.test");
    entity.setCargo("Operador de Empilhadeira");
    entity.setSetor("Estoque / Logística");
    entity.setStatus("Ativo");
    return entity;
  }

  static Treinamento treinamento() {
    var entity = new Treinamento();
    ReflectionTestUtils.setField(entity, "id", 2);
    entity.setCodigo("T02");
    entity.setNome("NR-11 Operação Segura de Empilhadeira");
    entity.setClassificacao("Obrigatório");
    entity.setCargaHoraria("8 horas");
    entity.setValidadeMeses(12);
    entity.setStatus("Ativo");
    return entity;
  }

  private ColaboradorTreinamento vinculo(LocalDate validade) {
    var entity = new ColaboradorTreinamento();
    entity.setColaborador(colaborador());
    entity.setTreinamento(treinamento());
    entity.setStatus("Concluído");
    entity.setValidade(validade);
    return entity;
  }

  private void stub(List<ColaboradorTreinamento> vinculos) {
    when(repository.findAll(Sort.by("id"))).thenReturn(vinculos);
  }

  @Test void listaTreinamentoVencido() {
    stub(List.of(vinculo(hoje.minusDays(1))));
    var lista = service.listar(hoje);
    assertEquals(1, lista.size());
    assertEquals("Vencido", lista.get(0).status());
    assertEquals(-1, lista.get(0).diasRestantes());
    assertEquals(hoje.minusDays(1), lista.get(0).prazoMaximo());
    assertEquals(1, lista.get(0).colaboradorId());
    assertEquals("Carlos Eduardo Silva", lista.get(0).colaborador());
    assertEquals("Operador de Empilhadeira", lista.get(0).cargo());
    assertEquals(2, lista.get(0).treinamentoId());
    assertEquals("NR-11 Operação Segura de Empilhadeira", lista.get(0).treinamento());
  }

  @Test void listaQuemVenceNaJanelaDeSessentaDias() {
    stub(List.of(vinculo(hoje), vinculo(hoje.plusDays(60))));
    var lista = service.listar(hoje);
    assertEquals(2, lista.size());
    assertEquals("Próximo do Vencimento", lista.get(0).status());
    assertEquals(60, lista.get(1).diasRestantes());
  }

  @Test void ignoraQuemVenceForaDaJanela() {
    stub(List.of(vinculo(hoje.plusDays(61))));
    assertTrue(service.listar(hoje).isEmpty());
  }

  @Test void ignoraVinculoSemValidade() {
    stub(List.of(vinculo(null)));
    assertTrue(service.listar(hoje).isEmpty());
  }

  @Test void ordenaPeloPrazoMaximoMaisAntigo() {
    stub(List.of(vinculo(hoje.plusDays(30)), vinculo(hoje.minusDays(10))));
    var lista = service.listar(hoje);
    assertEquals(hoje.minusDays(10), lista.get(0).prazoMaximo());
    assertEquals("Vencido", lista.get(0).status());
    assertEquals(hoje.plusDays(30), lista.get(1).prazoMaximo());
  }

  @Test void listarSemReferenciaUsaADataDeHoje() {
    stub(List.of(vinculo(LocalDate.now().minusDays(2))));
    assertEquals("Vencido", service.listar().get(0).status());
  }
}
