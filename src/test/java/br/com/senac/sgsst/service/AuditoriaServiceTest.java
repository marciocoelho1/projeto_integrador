package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.LogAuditoriaResponse;
import br.com.senac.sgsst.entity.LogAuditoria;
import br.com.senac.sgsst.entity.Usuario;
import br.com.senac.sgsst.exception.RequisicaoInvalidaException;
import br.com.senac.sgsst.repository.LogAuditoriaRepository;
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
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class AuditoriaServiceTest {

  final LogAuditoriaRepository repository = mock(LogAuditoriaRepository.class);
  final UsuarioRepository usuarios = mock(UsuarioRepository.class);
  final AuditoriaService service = new AuditoriaService(repository, usuarios);

  @AfterEach void limparContexto() { ContextoUsuario.limpar(); }

  @Test void registroCompletoGravaTodosOsCampos() {
    var usuario = mock(Usuario.class);
    when(usuario.getId()).thenReturn(7);
    when(usuarios.getReferenceById(7)).thenReturn(usuario);
    when(repository.saveAndFlush(any())).thenAnswer(chamada -> chamada.getArgument(0));

    var resposta = service.registrar(
      7, "Ana Souza", "colaboradores", "CRIACAO",
      "POST /api/colaboradores (201)", "POST", "/api/colaboradores", 201
    );

    assertAll(
      () -> assertEquals(7, resposta.usuarioId()),
      () -> assertEquals("Ana Souza", resposta.usuario()),
      () -> assertEquals("colaboradores", resposta.modulo()),
      () -> assertEquals("CRIACAO", resposta.acao()),
      () -> assertEquals("POST /api/colaboradores (201)", resposta.descricao()),
      () -> assertEquals("POST", resposta.metodo()),
      () -> assertEquals("/api/colaboradores", resposta.caminho()),
      () -> assertEquals(201, resposta.statusHttp()),
      () -> assertNotNull(resposta.dataHora())
    );
    verify(repository).saveAndFlush(any());
  }

  @Test void registroCompletoSemUsuarioNaoCriaVinculo() {
    when(repository.saveAndFlush(any())).thenAnswer(chamada -> chamada.getArgument(0));

    var resposta = service.registrar(
      null, null, "auth", "ACESSO",
      "POST /api/auth/login (401)", "POST", "/api/auth/login", 401
    );

    assertNull(resposta.usuarioId());
    assertEquals("auth", resposta.modulo());
    assertEquals("ACESSO", resposta.acao());
    verify(usuarios, never()).getReferenceById(any());
  }

  @Test void registroManualUsaUsuarioESessaoAtual() {
    var usuario = mock(Usuario.class);
    when(usuario.getId()).thenReturn(3);
    when(usuarios.getReferenceById(3)).thenReturn(usuario);
    when(repository.saveAndFlush(any())).thenAnswer(chamada -> chamada.getArgument(0));
    ContextoUsuario.definir(new UsuarioSessao(
      3, "admin", "Administrador TST", "Administrador TST", Set.of()
    ));

    var resposta = service.registrar(null, "Configurações", "EDICAO", "Alterou permissões");

    assertEquals(3, resposta.usuarioId());
    assertEquals("Administrador TST", resposta.usuario());
    assertEquals("MANUAL", resposta.metodo());
    assertEquals("/api/auditoria", resposta.caminho());
    assertEquals(201, resposta.statusHttp());
  }

  @Test void registroManualRespeitaNomeInformado() {
    when(repository.saveAndFlush(any())).thenAnswer(chamada -> chamada.getArgument(0));

    var resposta = service.registrar("Marcio Coelho", "Importação", "CRIACAO", "Importou 12 registros");

    assertEquals("Marcio Coelho", resposta.usuario());
    verify(usuarios, never()).getReferenceById(any());
  }

  @Test void rejeitaAcaoForaDaListaPermitida() {
    assertThrows(
      RequisicaoInvalidaException.class,
      () -> service.registrar(null, null, "epis", "HACKEAR", "x", "POST", "/api/epis", 200)
    );
    verify(repository, never()).saveAndFlush(any());
  }

  @Test void listaOrdenaDaMaisRecenteParaAMaisAntiga() {
    when(repository.findAll()).thenReturn(List.of(
      log("Ana", "epis", "Criou EPI", dia(10)),
      log("Ana", "epis", "Excluiu EPI", dia(12)),
      log("Ana", "epis", "Editou EPI", dia(11))
    ));

    assertEquals(
      List.of("Excluiu EPI", "Editou EPI", "Criou EPI"),
      descricoes(service.listar(null, null, null))
    );
  }

  @Test void filtraPorTermoIgnorandoCaixaEmUsuarioModuloEDescricao() {
    when(repository.findAll()).thenReturn(List.of(
      log("Ana Souza", "colaboradores", "Cadastrou colaborador", dia(10)),
      log("Bruno", "epis", "Criou EPI", dia(11))
    ));

    assertEquals(List.of("Criou EPI"), descricoes(service.listar("epi", null, null)));
    assertEquals(List.of("Cadastrou colaborador"), descricoes(service.listar("ANA", null, null)));
    assertEquals(List.of("Cadastrou colaborador"), descricoes(service.listar("cadastrou", null, null)));
    assertTrue(service.listar("inexistente", null, null).isEmpty());
  }

  @Test void filtraPeloIntervaloDeDatasInclusivo() {
    when(repository.findAll()).thenReturn(List.of(
      log("Ana", "epis", "Dia 10", dia(10)),
      log("Ana", "epis", "Dia 11", dia(11)),
      log("Ana", "epis", "Dia 12", dia(12))
    ));

    assertEquals(List.of("Dia 12", "Dia 11"), descricoes(service.listar(null, data(11), null)));
    assertEquals(List.of("Dia 11", "Dia 10"), descricoes(service.listar(null, null, data(11))));
    assertEquals(List.of("Dia 11"), descricoes(service.listar(null, data(11), data(11))));
  }

  @Test void combinaTermoEData() {
    when(repository.findAll()).thenReturn(List.of(
      log("Ana", "colaboradores", "Cadastrou colaborador", dia(10)),
      log("Bruno", "colaboradores", "Cadastrou colaborador", dia(12))
    ));

    assertEquals(
      List.of("Cadastrou colaborador"),
      descricoes(service.listar("bruno", data(11), data(12)))
    );
  }

  private List<String> descricoes(List<LogAuditoriaResponse> logs) {
    return logs.stream().map(LogAuditoriaResponse::descricao).toList();
  }

  private LogAuditoria log(String usuario, String modulo, String descricao, Instant dataHora) {
    var log = new LogAuditoria();
    log.setUsuarioNome(usuario);
    log.setModulo(modulo);
    log.setAcao("ACESSO");
    log.setDescricao(descricao);
    log.setMetodo("POST");
    log.setCaminho("/api/x");
    log.setStatusHttp(200);
    log.setDataHora(dataHora);
    return log;
  }

  private Instant dia(int dia) {
    return ZonedDateTime.of(LocalDate.of(2026, 1, dia), LocalTime.NOON, ZoneId.systemDefault()).toInstant();
  }

  private LocalDate data(int dia) {
    return LocalDate.of(2026, 1, dia);
  }
}
