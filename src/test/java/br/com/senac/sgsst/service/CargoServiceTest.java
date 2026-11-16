package br.com.senac.sgsst.service;
import br.com.senac.sgsst.dto.*;
import br.com.senac.sgsst.entity.*;
import br.com.senac.sgsst.repository.*;
import br.com.senac.sgsst.exception.*;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import java.util.*;
import org.springframework.data.domain.Sort;
import org.mockito.ArgumentCaptor;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
class CargoServiceTest {
  final CargoRepository repository = mock(CargoRepository.class);
  final CargoTreinamentoRepository matrizRepository = mock(CargoTreinamentoRepository.class);
  final TreinamentoRepository treinamentoRepository = mock(TreinamentoRepository.class);
  final CargoService service = new CargoService(repository, matrizRepository, treinamentoRepository);
  final CargoRequest request = new CargoRequest("Operador de Empilhadeira", "Estoque / Logística", "Ativo");

  static Cargo cargo() {
    var entity = new Cargo();
    ReflectionTestUtils.setField(entity, "id", 1);
    entity.setNome("Operador de Empilhadeira");
    entity.setSetor("Estoque / Logística");
    entity.setStatus("Ativo");
    return entity;
  }

  static Treinamento treinamento(Integer id) {
    var entity = new Treinamento();
    ReflectionTestUtils.setField(entity, "id", id);
    entity.setCodigo("T0" + id);
    entity.setNome("NR-11 Operação Segura de Empilhadeira");
    entity.setClassificacao("Obrigatório");
    entity.setCargaHoraria("8 horas");
    entity.setValidadeMeses(12);
    entity.setStatus("Ativo");
    return entity;
  }

  private CargoTreinamento vinculo(Treinamento treinamento, Boolean obrigatorio) {
    var entity = new CargoTreinamento();
    entity.setCargo(cargo());
    entity.setTreinamento(treinamento);
    entity.setObrigatorio(obrigatorio);
    return entity;
  }

  @Test void criaTodosOsCampos() {
    when(repository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));
    var response = service.criar(request);
    assertEquals("Operador de Empilhadeira", response.nome());
    assertEquals("Estoque / Logística", response.setor());
    assertEquals("Ativo", response.status());
  }

  @Test void listaOrdenada() {
    when(repository.findAll(Sort.by("nome", "id"))).thenReturn(List.of(cargo()));
    assertEquals("Operador de Empilhadeira", service.listar().get(0).nome());
  }

  @Test void buscaPorId() {
    when(repository.findById(1)).thenReturn(Optional.of(cargo()));
    assertEquals(1, service.buscarPorId(1).id());
  }

  @Test void atualizaTodosOsCampos() {
    var entity = mock(Cargo.class);
    when(entity.getId()).thenReturn(1);
    when(entity.getNome()).thenReturn("Operador de Empilhadeira");
    when(entity.getSetor()).thenReturn("Estoque / Logística");
    when(entity.getStatus()).thenReturn("Ativo");
    when(repository.findById(1)).thenReturn(Optional.of(entity));
    when(repository.saveAndFlush(entity)).thenReturn(entity);
    assertEquals("Estoque / Logística", service.atualizar(1, request).setor());
    verify(entity).setNome("Operador de Empilhadeira");
    verify(entity).setStatus("Ativo");
  }

  @Test void rejeitaNomeDuplicado() {
    when(repository.existsByNome("Operador de Empilhadeira")).thenReturn(true);
    assertThrows(ConflitoException.class, () -> service.criar(request));
    verify(repository, never()).saveAndFlush(any());
  }

  @Test void atualizacaoNaoPermiteNomeDeOutroCargo() {
    when(repository.findById(1)).thenReturn(Optional.of(cargo()));
    when(repository.existsByNomeAndIdNot("Operador de Empilhadeira", 1)).thenReturn(true);
    assertThrows(ConflitoException.class, () -> service.atualizar(1, request));
    verify(repository, never()).saveAndFlush(any());
  }

  @Test void excluiMatrizAntesDoCargo() {
    var entity = cargo();
    when(repository.findById(1)).thenReturn(Optional.of(entity));
    service.excluir(1);
    var ordem = inOrder(matrizRepository, repository);
    ordem.verify(matrizRepository).deleteByCargoId(1);
    ordem.verify(repository).delete(entity);
    verify(matrizRepository).flush();
    verify(repository).flush();
  }

  @Test void substituiMatrizDoCargo() {
    when(repository.findById(1)).thenReturn(Optional.of(cargo()));
    when(treinamentoRepository.findById(2)).thenReturn(Optional.of(treinamento(2)));
    when(matrizRepository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));
    var response = service.substituirMatriz(1, new CargoTreinamentosRequest(
      List.of(new CargoTreinamentoItemRequest(2, true))
    ));
    assertEquals("Operador de Empilhadeira", response.cargo());
    assertEquals(1, response.treinamentos().size());
    assertEquals(2, response.treinamentos().get(0).treinamentoId());
    assertEquals("NR-11 Operação Segura de Empilhadeira", response.treinamentos().get(0).treinamento());
    assertEquals(true, response.treinamentos().get(0).obrigatorio());
    var ordem = inOrder(matrizRepository);
    ordem.verify(matrizRepository).deleteByCargoId(1);
    ordem.verify(matrizRepository).saveAndFlush(any());
  }

  @Test void matrizAssumeObrigatorioVerdadeiroQuandoNaoInformado() {
    when(repository.findById(1)).thenReturn(Optional.of(cargo()));
    when(treinamentoRepository.findById(2)).thenReturn(Optional.of(treinamento(2)));
    when(matrizRepository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));
    service.substituirMatriz(1, new CargoTreinamentosRequest(
      List.of(new CargoTreinamentoItemRequest(2, null))
    ));
    var captor = ArgumentCaptor.forClass(CargoTreinamento.class);
    verify(matrizRepository).saveAndFlush(captor.capture());
    assertEquals(true, captor.getValue().getObrigatorio());
  }

  @Test void matrizVaziaLimpaOsTreinamentosDoCargo() {
    when(repository.findById(1)).thenReturn(Optional.of(cargo()));
    var response = service.substituirMatriz(1, new CargoTreinamentosRequest(List.of()));
    assertTrue(response.treinamentos().isEmpty());
    verify(matrizRepository).deleteByCargoId(1);
    verify(matrizRepository, never()).saveAndFlush(any());
  }

  @Test void matrizRejeitaTreinamentoInexistenteSemApagarAMatrizAtual() {
    when(repository.findById(1)).thenReturn(Optional.of(cargo()));
    assertThrows(RequisicaoInvalidaException.class, () -> service.substituirMatriz(1, new CargoTreinamentosRequest(
      List.of(new CargoTreinamentoItemRequest(99, true))
    )));
    verify(matrizRepository, never()).deleteByCargoId(any());
    verify(matrizRepository, never()).saveAndFlush(any());
  }

  @Test void matrizRejeitaTreinamentoRepetido() {
    when(repository.findById(1)).thenReturn(Optional.of(cargo()));
    assertThrows(RequisicaoInvalidaException.class, () -> service.substituirMatriz(1, new CargoTreinamentosRequest(
      List.of(new CargoTreinamentoItemRequest(2, true), new CargoTreinamentoItemRequest(2, false))
    )));
    verify(matrizRepository, never()).deleteByCargoId(any());
  }

  @Test void matrizRejeitaCargoInexistente() {
    assertThrows(RecursoNaoEncontradoException.class, () -> service.substituirMatriz(1, new CargoTreinamentosRequest(List.of())));
  }

  @Test void listarLntTrazOsTreinamentosDoCargo() {
    when(repository.findAll(Sort.by("nome", "id"))).thenReturn(List.of(cargo()));
    when(matrizRepository.findByCargoIdOrderByIdAsc(1)).thenReturn(List.of(vinculo(treinamento(2), true)));
    var lista = service.listarLnt();
    assertEquals(1, lista.size());
    assertEquals("Operador de Empilhadeira", lista.get(0).cargo());
    assertEquals("Estoque / Logística", lista.get(0).setor());
    assertEquals("Ativo", lista.get(0).status());
    assertEquals(1, lista.get(0).treinamentos().size());
    assertEquals("NR-11 Operação Segura de Empilhadeira", lista.get(0).treinamentos().get(0).treinamento());
    assertEquals(true, lista.get(0).treinamentos().get(0).obrigatorio());
  }

  @Test void inexistenteEmTodasOperacoes() {
    assertThrows(RecursoNaoEncontradoException.class, () -> service.buscarPorId(1));
    assertThrows(RecursoNaoEncontradoException.class, () -> service.atualizar(1, request));
    assertThrows(RecursoNaoEncontradoException.class, () -> service.excluir(1));
    assertThrows(RecursoNaoEncontradoException.class, () -> service.matrizPorCargo(1));
  }
}
