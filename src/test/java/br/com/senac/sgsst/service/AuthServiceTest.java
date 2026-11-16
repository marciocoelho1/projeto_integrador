package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.LoginRequest;
import br.com.senac.sgsst.dto.RecuperarSenhaRequest;
import br.com.senac.sgsst.dto.RedefinirSenhaRequest;
import br.com.senac.sgsst.entity.GrupoAcesso;
import br.com.senac.sgsst.entity.RedefinicaoSenha;
import br.com.senac.sgsst.entity.Sessao;
import br.com.senac.sgsst.entity.Usuario;
import br.com.senac.sgsst.exception.RecursoNaoEncontradoException;
import br.com.senac.sgsst.exception.RequisicaoInvalidaException;
import br.com.senac.sgsst.repository.RedefinicaoSenhaRepository;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Instant;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class AuthServiceTest {

  final UsuarioService usuarios = mock(UsuarioService.class);
  final SessaoService sessoes = mock(SessaoService.class);
  final RedefinicaoSenhaRepository redefinicoes = mock(RedefinicaoSenhaRepository.class);
  final AuthService service = new AuthService(usuarios, sessoes, redefinicoes);

  @Test void entrarDevolveTokenEIdentidade() {
    var usuario = usuario();
    var sessao = new Sessao();
    sessao.setToken("a".repeat(64));
    sessao.setUsuario(usuario);
    sessao.setCriadaEm(Instant.now());
    sessao.setExpiraEm(Instant.now().plusSeconds(3600));

    when(usuarios.autenticar("ana", "senha123")).thenReturn(usuario);
    when(sessoes.abrir(usuario)).thenReturn(sessao);

    var resposta = service.entrar(new LoginRequest("ana", "senha123"));

    assertEquals("a".repeat(64), resposta.token());
    assertEquals("ana", resposta.usuario().login());
    assertEquals("Administrador TST", resposta.usuario().grupo());
    assertTrue(resposta.usuario().modulos().contains("sgst_epis"));
  }

  @Test void sairAceitaSomenteCabecalhoBearer() {
    service.sair("Bearer token-123");
    verify(sessoes).encerrar("token-123");

    service.sair(null);
    service.sair("token-sem-bearer");
    verify(sessoes, times(1)).encerrar("token-123");
  }

  @Test void recuperarSenhaRespondeIgualParaUsuarioInexistente() {
    when(usuarios.buscarPorLoginOuEmail("ninguem"))
      .thenThrow(new RecursoNaoEncontradoException("Usuário não encontrado."));

    var resposta = service.solicitarRedefinicao(new RecuperarSenhaRequest("ninguem"));

    assertTrue(resposta.mensagem().contains("Solicitação registrada"));
    verify(redefinicoes, never()).saveAndFlush(any());
  }

  @Test void recuperarSenhaGravaTokenComValidade() {
    when(usuarios.buscarPorLoginOuEmail("ana")).thenReturn(usuario());
    when(redefinicoes.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));

    service.solicitarRedefinicao(new RecuperarSenhaRequest("ana"));

    var capturado = ArgumentCaptor.forClass(RedefinicaoSenha.class);
    verify(redefinicoes).saveAndFlush(capturado.capture());
    var salvo = capturado.getValue();

    assertEquals(64, salvo.getToken().length());
    assertTrue(salvo.getExpiraEm().isAfter(Instant.now()));
    assertNull(salvo.getUsadaEm());
  }

  @Test void listarRedefinicoesIgnoraUsadasEExpiradas() {
    var valida = redefinicao(1, "token-valido", Instant.now().plusSeconds(600), null);
    var usada = redefinicao(2, "token-usado", Instant.now().plusSeconds(600), Instant.now());
    var expirada = redefinicao(3, "token-expirado", Instant.now().minusSeconds(60), null);
    when(redefinicoes.findAll(any(org.springframework.data.domain.Sort.class)))
      .thenReturn(List.of(valida, usada, expirada));

    var pendentes = service.listarRedefinicoesPendentes();

    assertEquals(1, pendentes.size());
    assertEquals("token-valido", pendentes.get(0).token());
  }

  @Test void redefinirSenhaRejeitaTokenInvalidoUsadoEExpirado() {
    when(redefinicoes.findByToken("nao-existe")).thenReturn(Optional.empty());
    assertThrows(
      RequisicaoInvalidaException.class,
      () -> service.redefinirSenha(new RedefinirSenhaRequest("nao-existe", "novaSenha1"))
    );

    when(redefinicoes.findByToken("usado"))
      .thenReturn(Optional.of(redefinicao(4, "usado", Instant.now().plusSeconds(600), Instant.now())));
    assertThrows(
      RequisicaoInvalidaException.class,
      () -> service.redefinirSenha(new RedefinirSenhaRequest("usado", "novaSenha1"))
    );

    when(redefinicoes.findByToken("expirado"))
      .thenReturn(Optional.of(redefinicao(5, "expirado", Instant.now().minusSeconds(60), null)));
    assertThrows(
      RequisicaoInvalidaException.class,
      () -> service.redefinirSenha(new RedefinirSenhaRequest("expirado", "novaSenha1"))
    );

    verify(usuarios, never()).gravarNovaSenha(any(), any());
  }

  @Test void redefinirSenhaGravaNovaSenhaEMarcaUso() {
    var redefinicao = redefinicao(6, "ok", Instant.now().plusSeconds(600), null);
    when(redefinicoes.findByToken("ok")).thenReturn(Optional.of(redefinicao));
    when(redefinicoes.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));

    service.redefinirSenha(new RedefinirSenhaRequest("ok", "novaSenha1"));

    verify(usuarios).gravarNovaSenha(redefinicao.getUsuario(), "novaSenha1");
    assertNotNull(redefinicao.getUsadaEm());
  }

  private RedefinicaoSenha redefinicao(Integer id, String token, Instant expiraEm, Instant usadaEm) {
    var redefinicao = new RedefinicaoSenha();
    redefinicao.setUsuario(usuario());
    redefinicao.setToken(token);
    redefinicao.setCriadaEm(Instant.now());
    redefinicao.setExpiraEm(expiraEm);
    redefinicao.setUsadaEm(usadaEm);

    try {
      var field = RedefinicaoSenha.class.getDeclaredField("id");
      field.setAccessible(true);
      field.set(redefinicao, id);
    } catch (ReflectiveOperationException e) {
      throw new IllegalStateException(e);
    }

    return redefinicao;
  }

  private Usuario usuario() {
    var grupo = new GrupoAcesso();
    grupo.setNomenclatura("Administrador TST");
    grupo.setFinalidade("Teste");
    grupo.setModuloChaves(new LinkedHashSet<>(List.of("sgst_epis")));

    var usuario = new Usuario();
    usuario.setNomeCompleto("Ana Souza");
    usuario.setLogin("ana");
    usuario.setEmail("ana@example.test");
    usuario.setCpf("12345678901");
    usuario.setStatus("Ativo");
    usuario.setSenhaHash("hash");
    usuario.setGrupo(grupo);
    return usuario;
  }
}
