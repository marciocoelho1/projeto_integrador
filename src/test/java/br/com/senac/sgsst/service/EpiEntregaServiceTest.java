package br.com.senac.sgsst.service;
import br.com.senac.sgsst.dto.*;
import br.com.senac.sgsst.entity.*;
import br.com.senac.sgsst.repository.*;
import br.com.senac.sgsst.exception.*;
import org.junit.jupiter.api.Test;
import java.time.LocalDate;
import java.util.*;
import org.springframework.data.domain.Sort;
import org.springframework.test.util.ReflectionTestUtils;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
class EpiEntregaServiceTest {
  final EpiEntregaRepository repository = mock(EpiEntregaRepository.class);
  final EpiRepository epiRepository = mock(EpiRepository.class);
  final ColaboradorRepository colaboradorRepository = mock(ColaboradorRepository.class);
  final EpiEntregaService service = new EpiEntregaService(repository, epiRepository, colaboradorRepository);
  final EpiEntregaRequest request = new EpiEntregaRequest(1, 7, 2, LocalDate.of(2026,6,1), "Ana Ribeiro");

  private Colaborador colaborador() {
    var colaborador = new Colaborador();
    ReflectionTestUtils.setField(colaborador, "id", 1);
    colaborador.setMatricula("M01");
    colaborador.setNome("Ana Ribeiro");
    return colaborador;
  }
  private Epi epi(int quantidade) {
    var epi = new Epi();
    ReflectionTestUtils.setField(epi, "id", 7);
    epi.setDescricao("Capacete de Segurança");
    epi.setCa("123");
    epi.setInclusao(LocalDate.of(2026,1,1));
    epi.setValidade(LocalDate.of(2027,1,1));
    epi.setQuantidade(quantidade);
    return epi;
  }
  private EpiEntrega entrega(Epi epi, int quantidade) {
    var entrega = new EpiEntrega();
    entrega.setColaborador(colaborador());
    entrega.setEpi(epi);
    entrega.setQuantidade(quantidade);
    return entrega;
  }

  @Test void registraAbatendoOEstoqueEGuardandoOsDadosDoAto() {
    var epi = epi(10);
    when(colaboradorRepository.findById(1)).thenReturn(Optional.of(colaborador()));
    when(epiRepository.findById(7)).thenReturn(Optional.of(epi));
    when(repository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));

    var response = service.registrar(request);

    assertEquals(8, epi.getQuantidade());
    verify(epiRepository).saveAndFlush(epi);
    assertEquals(1, response.colaboradorId());
    assertEquals("Ana Ribeiro", response.colaborador());
    assertEquals("M01", response.matricula());
    assertEquals(7, response.epiId());
    assertEquals("Capacete de Segurança", response.epi());
    assertEquals("123", response.ca());
    assertEquals(2, response.quantidade());
    assertEquals(LocalDate.of(2026,6,1), response.dataEntrega());
    assertEquals("Ana Ribeiro", response.assinatura());
    assertNotNull(response.registradoEm());
  }

  @Test void estoqueInsuficienteRetorna409SemAlterarOEstoque() {
    var epi = epi(1);
    when(colaboradorRepository.findById(1)).thenReturn(Optional.of(colaborador()));
    when(epiRepository.findById(7)).thenReturn(Optional.of(epi));

    var erro = assertThrows(ConflitoException.class, () -> service.registrar(request));

    assertEquals("Estoque insuficiente para esta entrega. Disponível: 1.", erro.getMessage());
    assertEquals(1, epi.getQuantidade());
    verify(epiRepository, never()).saveAndFlush(any());
    verify(repository, never()).saveAndFlush(any());
  }

  @Test void registraComColaboradorOuEpiInexistenteRetorna404() {
    when(colaboradorRepository.findById(1)).thenReturn(Optional.empty());
    assertThrows(RecursoNaoEncontradoException.class, () -> service.registrar(request));

    when(colaboradorRepository.findById(1)).thenReturn(Optional.of(colaborador()));
    when(epiRepository.findById(7)).thenReturn(Optional.empty());
    assertThrows(RecursoNaoEncontradoException.class, () -> service.registrar(request));
  }

  @Test void idInexistenteEmTodasOperacoes() {
    when(repository.findById(99)).thenReturn(Optional.empty());
    assertThrows(RecursoNaoEncontradoException.class, () -> service.buscarPorId(99));
    assertThrows(RecursoNaoEncontradoException.class, () -> service.atualizar(99, request));
    assertThrows(RecursoNaoEncontradoException.class, () -> service.excluir(99));
  }

  @Test void excluirEstornaAQuantidadeAoEstoqueEApagaAEntrega() {
    var epi = epi(3);
    var entrega = entrega(epi, 2);
    when(repository.findById(5)).thenReturn(Optional.of(entrega));

    service.excluir(5);

    assertEquals(5, epi.getQuantidade());
    verify(epiRepository).saveAndFlush(epi);
    verify(repository).delete(entrega);
    verify(repository).flush();
  }

  @Test void atualizarEstornaOEAbateAoMoverAEntregaDeEpi() {
    var antigo = epi(4);
    var novo = epi(10);
    novo.setCa("999");
    var entrega = entrega(antigo, 2);
    when(repository.findById(5)).thenReturn(Optional.of(entrega));
    when(colaboradorRepository.findById(1)).thenReturn(Optional.of(colaborador()));
    when(epiRepository.findById(7)).thenReturn(Optional.of(novo));
    when(repository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));

    var response = service.atualizar(5, request);

    assertEquals(6, antigo.getQuantidade());
    assertEquals(8, novo.getQuantidade());
    assertEquals("999", response.ca());
    assertSame(novo, entrega.getEpi());
  }

  @Test void listarOrdenaDoMaisRecenteSemFiltro() {
    when(repository.findAll(EpiEntregaService.RECENTES_PRIMEIRO)).thenReturn(List.of(entrega(epi(1), 1)));
    assertEquals(1, service.listar(null).size());
    verify(repository, never()).findByColaboradorId(any(), any());
  }

  @Test void listarFiltraPeloColaboradorInformado() {
    when(repository.findByColaboradorId(1, EpiEntregaService.RECENTES_PRIMEIRO)).thenReturn(List.of(entrega(epi(1), 1)));

    var entregas = service.listar(1);

    assertEquals("Ana Ribeiro", entregas.get(0).colaborador());
    verify(repository, never()).findAll(any(Sort.class));
  }
}
