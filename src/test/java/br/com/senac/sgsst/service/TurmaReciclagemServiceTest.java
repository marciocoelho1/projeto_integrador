package br.com.senac.sgsst.service;
import br.com.senac.sgsst.dto.*;
import br.com.senac.sgsst.entity.*;
import br.com.senac.sgsst.repository.*;
import br.com.senac.sgsst.exception.*;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import java.time.LocalDate;
import java.util.*;
import org.springframework.data.domain.Sort;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
class TurmaReciclagemServiceTest {
  final TurmaReciclagemRepository repository = mock(TurmaReciclagemRepository.class);
  final TreinamentoRepository treinamentoRepository = mock(TreinamentoRepository.class);
  final TurmaReciclagemService service = new TurmaReciclagemService(repository, treinamentoRepository);
  final LocalDate data = LocalDate.of(2026, 7, 15);
  final TurmaReciclagemRequest request = new TurmaReciclagemRequest(2, "João Instrutor", data, 20, "Agendada");

  static Treinamento treinamento() {
    var entity = new Treinamento();
    ReflectionTestUtils.setField(entity, "id", 2);
    entity.setCodigo("T02");
    entity.setNome("NR-35 Trabalho em Altura");
    entity.setClassificacao("Obrigatório");
    entity.setCargaHoraria("8 horas");
    entity.setValidadeMeses(24);
    entity.setStatus("Ativo");
    return entity;
  }

  private TurmaReciclagem turma() {
    var entity = new TurmaReciclagem();
    entity.setTreinamento(treinamento());
    entity.setInstrutor("João Instrutor");
    entity.setDataAgendada(data);
    entity.setVagas(20);
    entity.setStatus("Agendada");
    return entity;
  }

  @Test void criaTodosOsCampos() {
    when(treinamentoRepository.findById(2)).thenReturn(Optional.of(treinamento()));
    when(repository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));
    var response = service.criar(request);
    assertEquals(2, response.treinamentoId());
    assertEquals("NR-35 Trabalho em Altura", response.treinamento());
    assertEquals("João Instrutor", response.instrutor());
    assertEquals(data, response.dataAgendada());
    assertEquals(20, response.vagas());
    assertEquals("Agendada", response.status());
  }

  @Test void atualizaTodosOsCampos() {
    var entity = turma();
    when(repository.findById(1)).thenReturn(Optional.of(entity));
    when(treinamentoRepository.findById(2)).thenReturn(Optional.of(treinamento()));
    when(repository.saveAndFlush(entity)).thenReturn(entity);
    var response = service.atualizar(1, new TurmaReciclagemRequest(2, "Maria Instrutora", data.plusDays(1), 0, "Concluída"));
    assertEquals("Maria Instrutora", response.instrutor());
    assertEquals(data.plusDays(1), response.dataAgendada());
    assertEquals(0, response.vagas());
    assertEquals("Concluída", response.status());
  }

  @Test void listaTodasAsTurmasSemFiltro() {
    when(repository.findAll(Sort.by("id"))).thenReturn(List.of(turma()));
    assertEquals("João Instrutor", service.listar(null).get(0).instrutor());
    verify(repository, never()).findByTreinamentoIdOrderByIdAsc(any());
  }

  @Test void listaFiltrandoPorTreinamento() {
    when(repository.findByTreinamentoIdOrderByIdAsc(2)).thenReturn(List.of(turma()));
    assertEquals(1, service.listar(2).size());
    verify(repository, never()).findAll(Sort.by("id"));
  }

  @Test void buscaPorIdEEclui() {
    var entity = turma();
    when(repository.findById(5)).thenReturn(Optional.of(entity));
    assertEquals("Agendada", service.buscarPorId(5).status());
    service.excluir(5);
    verify(repository).delete(entity);
    verify(repository).flush();
  }

  @Test void rejeitaTreinamentoInexistente() {
    assertThrows(RequisicaoInvalidaException.class, () -> service.criar(request));
    verify(repository, never()).saveAndFlush(any());
  }

  @Test void inexistenteEmTodasOperacoes() {
    assertThrows(RecursoNaoEncontradoException.class, () -> service.buscarPorId(1));
    assertThrows(RecursoNaoEncontradoException.class, () -> service.atualizar(1, request));
    assertThrows(RecursoNaoEncontradoException.class, () -> service.excluir(1));
  }
}
