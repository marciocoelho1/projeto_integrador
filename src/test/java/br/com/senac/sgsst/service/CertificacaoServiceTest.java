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
class CertificacaoServiceTest {
  final CertificacaoRepository repository = mock(CertificacaoRepository.class);
  final ColaboradorRepository colaboradorRepository = mock(ColaboradorRepository.class);
  final TreinamentoRepository treinamentoRepository = mock(TreinamentoRepository.class);
  final CertificacaoService service = new CertificacaoService(repository, colaboradorRepository, treinamentoRepository);
  final LocalDate emissao = LocalDate.of(2026, 1, 10);
  final LocalDate validade = LocalDate.of(2027, 1, 10);
  final CertificacaoRequest request = new CertificacaoRequest(1, 2, "SENAC", "8 horas", emissao, validade, "https://exemplo.test/certificado.pdf");

  static Colaborador colaborador() {
    var entity = new Colaborador();
    ReflectionTestUtils.setField(entity, "id", 1);
    entity.setMatricula("M01");
    entity.setNome("Ana Paula Souza");
    entity.setCpf("12345678901");
    entity.setEmail("ana@example.test");
    entity.setCargo("Operadora de Caixa");
    entity.setSetor("Frente de Loja");
    entity.setStatus("Ativo");
    return entity;
  }

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

  private void stubCertificacaoValida() {
    when(colaboradorRepository.findById(1)).thenReturn(Optional.of(colaborador()));
    when(treinamentoRepository.findById(2)).thenReturn(Optional.of(treinamento()));
    when(repository.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));
  }

  @Test void criaTodosOsCamposECalculaStatus() {
    stubCertificacaoValida();
    var response = service.criar(request);
    assertEquals("SENAC", response.instituicao());
    assertEquals("8 horas", response.cargaHoraria());
    assertEquals(emissao, response.emitidaEm());
    assertEquals(validade, response.validade());
    assertEquals("https://exemplo.test/certificado.pdf", response.arquivoUrl());
    assertEquals(1, response.colaboradorId());
    assertEquals("Ana Paula Souza", response.colaborador());
    assertEquals("Operadora de Caixa", response.cargo());
    assertEquals(2, response.treinamentoId());
    assertEquals("NR-35 Trabalho em Altura", response.treinamento());
  }

  @Test void statusDaCertificacaoSegueVencimento() {
    var referencia = LocalDate.of(2026, 6, 1);
    assertEquals("Vencida", CertificacaoResponse.statusDe(referencia.minusDays(1), referencia));
    assertEquals("Alerta", CertificacaoResponse.statusDe(referencia.plusDays(60), referencia));
    assertEquals("Alerta", CertificacaoResponse.statusDe(referencia, referencia));
    assertEquals("Ativa", CertificacaoResponse.statusDe(referencia.plusDays(61), referencia));
    assertEquals("Ativa", CertificacaoResponse.statusDe(null, referencia));
  }

  @Test void listaTodasAsCertificacoesSemFiltro() {
    when(repository.findAll(Sort.by("id"))).thenReturn(List.of(new Certificacao()));
    assertEquals(1, service.listar(null).size());
    verify(repository, never()).findByColaboradorIdOrderByIdAsc(any());
  }

  @Test void listaFiltrandoPorColaborador() {
    var entity = new Certificacao();
    entity.setColaborador(colaborador());
    entity.setTreinamento(treinamento());
    when(repository.findByColaboradorIdOrderByIdAsc(1)).thenReturn(List.of(entity));
    var lista = service.listar(1);
    assertEquals(1, lista.size());
    assertEquals("Ana Paula Souza", lista.get(0).colaborador());
    assertEquals("NR-35 Trabalho em Altura", lista.get(0).treinamento());
    verify(repository, never()).findAll(Sort.by("id"));
  }

  @Test void rejeitaCertificacaoDuplicadaNaMesmaValidade() {
    when(repository.existsByColaboradorIdAndTreinamentoIdAndValidade(1, 2, validade)).thenReturn(true);
    assertThrows(ConflitoException.class, () -> service.criar(request));
    verify(repository, never()).saveAndFlush(any());
  }

  @Test void permiteMesmoTreinamentoComOutraValidade() {
    when(repository.existsByColaboradorIdAndTreinamentoIdAndValidade(1, 2, validade)).thenReturn(false);
    stubCertificacaoValida();
    var reciclagem = new CertificacaoRequest(1, 2, "SENAC", "8 horas", validade, validade.plusYears(2), null);
    assertEquals(validade.plusYears(2), service.criar(reciclagem).validade());
  }

  @Test void atualizacaoNaoPermiteDuplicarOutraCertificacao() {
    when(repository.findById(9)).thenReturn(Optional.of(new Certificacao()));
    when(repository.existsByColaboradorIdAndTreinamentoIdAndValidadeAndIdNot(1, 2, validade, 9)).thenReturn(true);
    assertThrows(ConflitoException.class, () -> service.atualizar(9, request));
    verify(repository, never()).saveAndFlush(any());
  }

  @Test void atualizaTodosOsCampos() {
    var entity = new Certificacao();
    when(repository.findById(9)).thenReturn(Optional.of(entity));
    stubCertificacaoValida();
    when(repository.saveAndFlush(entity)).thenReturn(entity);
    var response = service.atualizar(9, request);
    assertEquals("SENAC", entity.getInstituicao());
    assertEquals(emissao, entity.getEmitidaEm());
    assertEquals(validade, response.validade());
    assertEquals("https://exemplo.test/certificado.pdf", entity.getArquivoUrl());
  }

  @Test void buscaPorIdEEclui() {
    var entity = new Certificacao();
    entity.setInstituicao("SENAC");
    when(repository.findById(3)).thenReturn(Optional.of(entity));
    assertEquals("SENAC", service.buscarPorId(3).instituicao());
    service.excluir(3);
    verify(repository).delete(entity);
    verify(repository).flush();
  }

  @Test void rejeitaColaboradorOuTreinamentoInexistente() {
    assertThrows(RequisicaoInvalidaException.class, () -> service.criar(request));
    when(colaboradorRepository.findById(1)).thenReturn(Optional.of(colaborador()));
    assertThrows(RequisicaoInvalidaException.class, () -> service.criar(request));
    verify(repository, never()).saveAndFlush(any());
  }

  @Test void inexistenteEmTodasOperacoes() {
    assertThrows(RecursoNaoEncontradoException.class, () -> service.buscarPorId(1));
    assertThrows(RecursoNaoEncontradoException.class, () -> service.atualizar(1, request));
    assertThrows(RecursoNaoEncontradoException.class, () -> service.excluir(1));
  }
}
