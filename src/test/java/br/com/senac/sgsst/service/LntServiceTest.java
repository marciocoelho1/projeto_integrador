package br.com.senac.sgsst.service;
import br.com.senac.sgsst.dto.*;
import br.com.senac.sgsst.entity.*;
import br.com.senac.sgsst.repository.*;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import java.util.*;
import org.springframework.data.domain.Sort;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
class LntServiceTest {
  final CargoService cargoService = mock(CargoService.class);
  final CargoTreinamentoRepository matrizRepository = mock(CargoTreinamentoRepository.class);
  final ColaboradorRepository colaboradorRepository = mock(ColaboradorRepository.class);
  final ColaboradorTreinamentoRepository vinculoRepository = mock(ColaboradorTreinamentoRepository.class);
  final LntService service = new LntService(cargoService, matrizRepository, colaboradorRepository, vinculoRepository);

  static Colaborador colaborador(Integer id, String cargo) {
    var entity = new Colaborador();
    ReflectionTestUtils.setField(entity, "id", id);
    entity.setMatricula("M0" + id);
    entity.setNome("Colaborador " + id);
    entity.setCpf("1234567890" + id);
    entity.setEmail("colaborador" + id + "@example.test");
    entity.setCargo(cargo);
    entity.setSetor("Frente de Loja");
    entity.setStatus("Ativo");
    return entity;
  }

  static Treinamento treinamento(Integer id, String nome) {
    var entity = new Treinamento();
    ReflectionTestUtils.setField(entity, "id", id);
    entity.setCodigo("T0" + id);
    entity.setNome(nome);
    entity.setClassificacao("Obrigatório");
    entity.setCargaHoraria("8 horas");
    entity.setValidadeMeses(12);
    entity.setStatus("Ativo");
    return entity;
  }

  private CargoTreinamento matriz(String nomeDoCargo, Treinamento treinamento, Boolean obrigatorio) {
    var cargo = new Cargo();
    ReflectionTestUtils.setField(cargo, "id", 1);
    cargo.setNome(nomeDoCargo);
    cargo.setSetor("Frente de Loja");
    cargo.setStatus("Ativo");
    var entity = new CargoTreinamento();
    entity.setCargo(cargo);
    entity.setTreinamento(treinamento);
    entity.setObrigatorio(obrigatorio);
    return entity;
  }

  private ColaboradorTreinamento vinculo(Colaborador colaborador, Treinamento treinamento, String status) {
    var entity = new ColaboradorTreinamento();
    entity.setColaborador(colaborador);
    entity.setTreinamento(treinamento);
    entity.setStatus(status);
    return entity;
  }

  @Test void listaCargosComAMatrizObrigatoria() {
    when(cargoService.listarLnt()).thenReturn(List.of(new LntResponse(1, "Operador de Caixa", "Frente de Loja", "Ativo",
      List.of(new CargoTreinamentoResponse(1, 2, "NR-17 Ergonomia", "NR-17", true)))));
    var lista = service.listarCargos();
    assertEquals("Operador de Caixa", lista.get(0).cargo());
    assertEquals("NR-17 Ergonomia", lista.get(0).treinamentos().get(0).treinamento());
  }

  @Test void colaboradorFicaPendenteQuandoNaoConcluiuTreinamentoObrigatorio() {
    when(matrizRepository.findByObrigatorioTrueOrderByIdAsc()).thenReturn(List.of(
      matriz("Operador de Empilhadeira", treinamento(2, "NR-11 Operação Segura de Empilhadeira"), true)));
    when(vinculoRepository.findAll()).thenReturn(List.of());
    when(colaboradorRepository.findAll(Sort.by("nome", "id"))).thenReturn(List.of(colaborador(1, "Operador de Empilhadeira")));
    var lista = service.listarColaboradores();
    assertEquals("Pendente", lista.get(0).status());
    assertEquals(List.of("NR-11 Operação Segura de Empilhadeira"), lista.get(0).treinamentosPendentes());
    assertEquals("Colaborador 1", lista.get(0).colaborador());
    assertEquals("Frente de Loja", lista.get(0).setor());
  }

  @Test void colaboradorFicaConformeAoConcluirObrigatorio() {
    var treinamento = treinamento(2, "NR-11 Operação Segura de Empilhadeira");
    var colaborador = colaborador(1, "Operador de Empilhadeira");
    when(matrizRepository.findByObrigatorioTrueOrderByIdAsc()).thenReturn(List.of(matriz("Operador de Empilhadeira", treinamento, true)));
    when(vinculoRepository.findAll()).thenReturn(List.of(vinculo(colaborador, treinamento, "Concluído")));
    when(colaboradorRepository.findAll(Sort.by("nome", "id"))).thenReturn(List.of(colaborador));
    var lista = service.listarColaboradores();
    assertEquals("Conforme", lista.get(0).status());
    assertTrue(lista.get(0).treinamentosPendentes().isEmpty());
  }

  @Test void vinculoEmAndamentoNaoContaComoTreinamentoConcluido() {
    var treinamento = treinamento(2, "NR-35 Trabalho em Altura");
    var colaborador = colaborador(1, "Operador de Empilhadeira");
    when(matrizRepository.findByObrigatorioTrueOrderByIdAsc()).thenReturn(List.of(matriz("Operador de Empilhadeira", treinamento, true)));
    when(vinculoRepository.findAll()).thenReturn(List.of(vinculo(colaborador, treinamento, "Em Andamento")));
    when(colaboradorRepository.findAll(Sort.by("nome", "id"))).thenReturn(List.of(colaborador));
    assertEquals("Pendente", service.listarColaboradores().get(0).status());
  }

  @Test void matrizDeOutroCargoNaoGeraPendencia() {
    when(matrizRepository.findByObrigatorioTrueOrderByIdAsc()).thenReturn(List.of(
      matriz("Operador de Empilhadeira", treinamento(2, "NR-11 Operação Segura de Empilhadeira"), true)));
    when(vinculoRepository.findAll()).thenReturn(List.of());
    when(colaboradorRepository.findAll(Sort.by("nome", "id"))).thenReturn(List.of(colaborador(1, "Operadora de Caixa")));
    assertEquals("Conforme", service.listarColaboradores().get(0).status());
  }

  @Test void treinamentoNaoObrigatorioNaoEntraNoLnt() {
    when(matrizRepository.findByObrigatorioTrueOrderByIdAsc()).thenReturn(List.of(
      matriz("Operador de Empilhadeira", treinamento(2, "NR-23 Brigada de Incêndio"), false)));
    when(vinculoRepository.findAll()).thenReturn(List.of());
    when(colaboradorRepository.findAll(Sort.by("nome", "id"))).thenReturn(List.of(colaborador(1, "Operador de Empilhadeira")));
    assertEquals("Conforme", service.listarColaboradores().get(0).status());
  }

  @Test void colaboradorSemCargoComMatrizFicaConforme() {
    when(matrizRepository.findByObrigatorioTrueOrderByIdAsc()).thenReturn(List.of());
    when(vinculoRepository.findAll()).thenReturn(List.of());
    when(colaboradorRepository.findAll(Sort.by("nome", "id"))).thenReturn(List.of(colaborador(1, "Açougueiro")));
    var lista = service.listarColaboradores();
    assertEquals(1, lista.size());
    assertEquals("Conforme", lista.get(0).status());
    assertTrue(lista.get(0).treinamentosPendentes().isEmpty());
  }
}
