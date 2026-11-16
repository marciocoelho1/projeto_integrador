package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.ChamadoRequest;
import br.com.senac.sgsst.dto.ChamadoResponse;
import br.com.senac.sgsst.entity.Chamado;
import br.com.senac.sgsst.entity.Usuario;
import br.com.senac.sgsst.exception.ConflitoException;
import br.com.senac.sgsst.exception.CredencialInvalidaException;
import br.com.senac.sgsst.exception.RecursoNaoEncontradoException;
import br.com.senac.sgsst.exception.RequisicaoInvalidaException;
import br.com.senac.sgsst.repository.ChamadoRepository;
import br.com.senac.sgsst.repository.UsuarioRepository;
import br.com.senac.sgsst.security.ContextoUsuario;
import br.com.senac.sgsst.security.UsuarioSessao;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ChamadoServiceTest {

  final ChamadoRepository repository = mock(ChamadoRepository.class);
  final UsuarioRepository usuarios = mock(UsuarioRepository.class);
  final ChamadoService service = new ChamadoService(repository, usuarios);

  @AfterEach void limparContexto() { ContextoUsuario.limpar(); }

  @Test void listarMeusFiltraPeloUsuarioDaSessao() {
    definirSessao(7);
    var dono = usuario(7);
    when(repository.findByUsuarioId(7)).thenReturn(List.of(
      chamado("Ajuda", "Pedido antigo", ChamadoService.EM_ANDAMENTO, dono, dia(10)),
      chamado("Erro", "Pedido novo", ChamadoService.CONCLUIDA, dono, dia(12))
    ));

    var lista = service.listar(null, true);

    assertEquals(List.of("Pedido novo", "Pedido antigo"), descricoes(lista));
    verify(repository).findByUsuarioId(7);
    verify(repository, never()).findAll();
  }

  @Test void listarMeusSemSessaoRecusa() {
    assertThrows(CredencialInvalidaException.class, () -> service.listar(null, true));
    verify(repository, never()).findAll();
    verify(repository, never()).findByUsuarioId(any());
  }

  @Test void listarGeralFiltraPorStatus() {
    when(repository.findAll()).thenReturn(List.of(
      chamado("Ajuda", "Em aberto", ChamadoService.EM_ANDAMENTO, null, dia(10)),
      chamado("Erro", "Fechado", ChamadoService.CONCLUIDA, null, dia(11))
    ));

    assertEquals(List.of("Fechado"), descricoes(service.listar(ChamadoService.CONCLUIDA, false)));
    assertEquals(2, service.listar(null, false).size());
  }

  @Test void criarUsaStatusEmAndamentoESolicitanteDaSessao() {
    definirSessao(7);
    var dono = usuario(7);
    when(usuarios.getReferenceById(7)).thenReturn(dono);
    when(repository.saveAndFlush(any())).thenAnswer(chamada -> chamada.getArgument(0));

    var resposta = service.criar(new ChamadoRequest(
      " Erro ", "  Erro ao gerar relatório  ", null, null
    ));

    assertEquals("Erro", resposta.tipo());
    assertEquals("Erro ao gerar relatório", resposta.descricao());
    assertEquals(ChamadoService.EM_ANDAMENTO, resposta.status());
    assertEquals("Colaborador", resposta.solicitante());
    assertEquals(7, resposta.usuarioId());
    assertNotNull(resposta.abertoEm());
    assertNull(resposta.concluidoEm());
  }

  @Test void criarRespeitaSolicitanteInformadoSemSessao() {
    when(repository.saveAndFlush(any())).thenAnswer(chamada -> chamada.getArgument(0));

    var resposta = service.criar(new ChamadoRequest("Ajuda", "Dúvida", "Cancelada", "Visitante"));

    assertEquals("Visitante", resposta.solicitante());
    assertNull(resposta.usuarioId());
    assertEquals(ChamadoService.EM_ANDAMENTO, resposta.status(), "criar sempre abre em andamento");
    verify(usuarios, never()).getReferenceById(any());
  }

  @Test void criarSemSolicitanteNemSessaoRecusa() {
    assertThrows(
      CredencialInvalidaException.class,
      () -> service.criar(new ChamadoRequest("Ajuda", "Dúvida", null, null))
    );
    verify(repository, never()).saveAndFlush(any());
  }

  @Test void concluirPreencheConcluidoEm() {
    var chamado = chamado("Ajuda", "Dúvida", ChamadoService.EM_ANDAMENTO, null, dia(10));
    when(repository.findById(1)).thenReturn(Optional.of(chamado));
    when(repository.saveAndFlush(any())).thenAnswer(chamada -> chamada.getArgument(0));

    var resposta = service.atualizarStatus(1, ChamadoService.CONCLUIDA);

    assertEquals(ChamadoService.CONCLUIDA, resposta.status());
    assertNotNull(resposta.concluidoEm());
  }

  @Test void sairDeConcluidaLimpaConcluidoEm() {
    var chamado = chamado("Ajuda", "Dúvida", ChamadoService.CONCLUIDA, null, dia(10));
    chamado.setConcluidoEm(dia(11));
    when(repository.findById(1)).thenReturn(Optional.of(chamado));
    when(repository.saveAndFlush(any())).thenAnswer(c -> c.getArgument(0));

    var resposta = service.atualizarStatus(1, ChamadoService.EM_ANDAMENTO);

    assertEquals(ChamadoService.EM_ANDAMENTO, resposta.status());
    assertNull(resposta.concluidoEm());
  }

  @Test void statusInvalidoRetornaRequisicaoInvalida() {
    assertThrows(RequisicaoInvalidaException.class, () -> service.atualizarStatus(1, "Pendente"));
    assertThrows(RequisicaoInvalidaException.class, () -> service.atualizarStatus(1, null));
    verify(repository, never()).findById(any());
  }

  @Test void chamadoCanceladoNaoPodeSerAlterado() {
    var chamado = chamado("Ajuda", "Dúvida", ChamadoService.CANCELADA, null, dia(10));
    when(repository.findById(1)).thenReturn(Optional.of(chamado));

    assertThrows(ConflitoException.class, () -> service.atualizarStatus(1, ChamadoService.CONCLUIDA));
    verify(repository, never()).saveAndFlush(any());
  }

  @Test void inexistenteRetornaNaoEncontrado() {
    assertThrows(RecursoNaoEncontradoException.class, () -> service.buscarPorId(404));
    assertThrows(
      RecursoNaoEncontradoException.class,
      () -> service.atualizarStatus(404, ChamadoService.CONCLUIDA)
    );
    assertThrows(RecursoNaoEncontradoException.class, () -> service.excluir(404));
  }

  @Test void excluiExecutaFlush() {
    var chamado = chamado("Ajuda", "Dúvida", ChamadoService.EM_ANDAMENTO, null, dia(10));
    when(repository.findById(1)).thenReturn(Optional.of(chamado));

    service.excluir(1);

    verify(repository).delete(chamado);
    verify(repository).flush();
  }

  private List<String> descricoes(List<ChamadoResponse> chamados) {
    return chamados.stream().map(ChamadoResponse::descricao).toList();
  }

  private void definirSessao(Integer id) {
    ContextoUsuario.definir(new UsuarioSessao(
      id, "colaborador", "Colaborador", "Colaborador", Set.of()
    ));
  }

  private Usuario usuario(Integer id) {
    var usuario = mock(Usuario.class);
    when(usuario.getId()).thenReturn(id);
    return usuario;
  }

  private Chamado chamado(
    String tipo, String descricao, String status, Usuario usuario, Instant abertoEm
  ) {
    var chamado = new Chamado();
    chamado.setTipo(tipo);
    chamado.setDescricao(descricao);
    chamado.setStatus(status);
    chamado.setSolicitante("Colaborador");
    chamado.setUsuario(usuario);
    chamado.setAbertoEm(abertoEm);
    return chamado;
  }

  private Instant dia(int dia) {
    return ZonedDateTime.of(LocalDate.of(2026, 1, dia), LocalTime.NOON, ZoneId.systemDefault()).toInstant();
  }
}
