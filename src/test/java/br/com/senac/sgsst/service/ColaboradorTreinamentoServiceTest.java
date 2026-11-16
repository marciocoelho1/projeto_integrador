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
class ColaboradorTreinamentoServiceTest {
  final ColaboradorTreinamentoRepository repository = mock(ColaboradorTreinamentoRepository.class);
  final ColaboradorRepository colaboradorRepository = mock(ColaboradorRepository.class);
  final TreinamentoRepository treinamentoRepository = mock(TreinamentoRepository.class);
  final ColaboradorTreinamentoService service = new ColaboradorTreinamentoService(repository, colaboradorRepository, treinamentoRepository);
  final LocalDate conclusao = LocalDate.of(2026, 3, 10);
  final ColaboradorTreinamentoRequest request = new ColaboradorTreinamentoRequest(1, 2, conclusao, "Concluído");

  static Colaborador colaborador(Integer id) {
    var entity = new Colaborador();
    ReflectionTestUtils.setField(entity, "id", id);
    entity.setMatricula("M01");
    entity.setNome("Ana Paula Souza");
    entity.setCpf("12345678901");
    entity.setEmail("ana@example.test");
    entity.setCargo("Repositora");
    entity.setSetor("Frente de Loja");
    entity.setStatus("Ativo");
    return entity;
  }

  static Treinamento treinamento(Integer id, String nome, Integer validadeMeses) {
    var entity = new Treinamento();
    ReflectionTestUtils.setField(entity, "id", id);
    entity.setCodigo("T0" + id);
    entity.setNome(nome);
    entity.setClassificacao("Obrigatório");
    entity.setCargaHoraria("8 horas");
    entity.setValidadeMeses(validadeMeses);
    entity.setStatus("Ativo");
    return entity;
  }

  private void stubVinculoValido(Integer validadeMeses) {
    when(colaboradorRepository.findById(1)).thenReturn(Optional.of(colaborador(1)));
    when(treinamentoRepository.findById(2)).thenReturn(Optional.of(treinamento(2, "NR-06 Uso Adequado e Guarda de EPIs", validadeMeses)));
    when(repository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));
  }

  @Test void criaCalculandoValidadePelaValidadeEmMesesDoTreinamento() {
    stubVinculoValido(12);
    var response = service.criar(request);
    assertEquals("Concluído", response.status());
    assertEquals(conclusao, response.dataConclusao());
    assertEquals(conclusao.plusMonths(12), response.validade());
    assertEquals(1, response.colaboradorId());
    assertEquals("Ana Paula Souza", response.colaborador());
    assertEquals("Repositora", response.cargo());
    assertEquals(2, response.treinamentoId());
    assertEquals("NR-06 Uso Adequado e Guarda de EPIs", response.treinamento());
  }

  @Test void criaSemValidadeQuandoTreinamentoNaoTemPrazoPadrao() {
    stubVinculoValido(null);
    assertNull(service.criar(request).validade());
  }

  @Test void criaSemValidadeQuandoNaoHaDataDeConclusao() {
    stubVinculoValido(24);
    var semConclusao = new ColaboradorTreinamentoRequest(1, 2, null, "Pendente");
    var response = service.criar(semConclusao);
    assertEquals("Pendente", response.status());
    assertNull(response.dataConclusao());
    assertNull(response.validade());
  }

  @Test void calculoDeValidadeAceitaPrazoZero() {
    assertEquals(conclusao, ColaboradorTreinamentoService.calcularValidade(conclusao, 0));
    assertNull(ColaboradorTreinamentoService.calcularValidade(null, 12));
    assertNull(ColaboradorTreinamentoService.calcularValidade(conclusao, null));
  }

  @Test void rejeitaVinculoDuplicadoDoMesmoPar() {
    when(repository.existsByColaboradorIdAndTreinamentoId(1, 2)).thenReturn(true);
    assertThrows(ConflitoException.class, () -> service.criar(request));
    verify(repository, never()).saveAndFlush(any());
  }

  @Test void atualizacaoNaoPermiteDuplicarOutroVinculo() {
    when(repository.findById(5)).thenReturn(Optional.of(new ColaboradorTreinamento()));
    when(repository.existsByColaboradorIdAndTreinamentoIdAndIdNot(1, 2, 5)).thenReturn(true);
    assertThrows(ConflitoException.class, () -> service.atualizar(5, request));
    verify(repository, never()).saveAndFlush(any());
  }

  @Test void atualizaTodosOsCamposDoVinculo() {
    var entity = new ColaboradorTreinamento();
    when(repository.findById(5)).thenReturn(Optional.of(entity));
    stubVinculoValido(6);
    when(repository.saveAndFlush(entity)).thenReturn(entity);
    var response = service.atualizar(5, request);
    assertEquals("Concluído", entity.getStatus());
    assertEquals(conclusao.plusMonths(6), response.validade());
  }

  @Test void listaTodosOsVinculosSemFiltro() {
    var entity = new ColaboradorTreinamento();
    when(repository.findAll(Sort.by("id"))).thenReturn(List.of(entity));
    assertEquals(1, service.listar(null).size());
    assertNull(service.listar(null).get(0).colaborador());
    verify(repository, never()).findByColaboradorIdOrderByIdAsc(any());
  }

  @Test void listaFiltrandoPorColaborador() {
    var entity = new ColaboradorTreinamento();
    entity.setColaborador(colaborador(1));
    entity.setTreinamento(treinamento(2, "NR-06 Uso Adequado e Guarda de EPIs", 12));
    when(repository.findByColaboradorIdOrderByIdAsc(7)).thenReturn(List.of(entity));
    var lista = service.listar(7);
    assertEquals(1, lista.size());
    assertEquals("Ana Paula Souza", lista.get(0).colaborador());
    verify(repository, never()).findAll(Sort.by("id"));
  }

  @Test void buscaPorIdDevolveVinculoCompleto() {
    var entity = new ColaboradorTreinamento();
    entity.setColaborador(colaborador(1));
    entity.setTreinamento(treinamento(2, "NR-06 Uso Adequado e Guarda de EPIs", 12));
    entity.setStatus("Em Andamento");
    when(repository.findById(3)).thenReturn(Optional.of(entity));
    assertEquals("Em Andamento", service.buscarPorId(3).status());
    assertEquals("NR-06 Uso Adequado e Guarda de EPIs", service.buscarPorId(3).treinamento());
  }

  @Test void excluiEExecutaFlush() {
    var entity = new ColaboradorTreinamento();
    when(repository.findById(4)).thenReturn(Optional.of(entity));
    service.excluir(4);
    verify(repository).delete(entity);
    verify(repository).flush();
  }

  @Test void inexistenteEmTodasOperacoes() {
    assertThrows(RecursoNaoEncontradoException.class, () -> service.buscarPorId(1));
    assertThrows(RecursoNaoEncontradoException.class, () -> service.atualizar(1, request));
    assertThrows(RecursoNaoEncontradoException.class, () -> service.excluir(1));
  }

  @Test void rejeitaColaboradorInexistenteComBadRequest() {
    when(repository.existsByColaboradorIdAndTreinamentoId(1, 2)).thenReturn(false);
    assertThrows(RequisicaoInvalidaException.class, () -> service.criar(request));
    verify(repository, never()).saveAndFlush(any());
  }

  @Test void rejeitaTreinamentoInexistenteComBadRequest() {
    when(colaboradorRepository.findById(1)).thenReturn(Optional.of(colaborador(1)));
    assertThrows(RequisicaoInvalidaException.class, () -> service.criar(request));
    verify(repository, never()).saveAndFlush(any());
  }
}
