package br.com.senac.sgsst.security;

import br.com.senac.sgsst.service.SessaoService;
import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import java.util.Optional;
import java.util.Set;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class AutenticacaoFilterTest {

  final SessaoService sessoes = mock(SessaoService.class);
  final AutenticacaoFilter filtro = new AutenticacaoFilter(sessoes);

  @AfterEach void limparContexto() {
    ContextoUsuario.limpar();
  }

  @Test void rotasLivresNaoExigemSessao() throws Exception {
    for (String caminho : new String[]{
      "/api/health",
      "/api/auth/login",
      "/api/auth/bootstrap",
      "/api/auth/recuperar-senha",
      "/api/auth/redefinir-senha"
    }) {
      var chamou = new AtomicBoolean(false);
      var resposta = new MockHttpServletResponse();

      filtro.doFilter(
        requisicao("GET", caminho, null),
        resposta,
        cadeia(chamou)
      );

      assertTrue(chamou.get(), caminho + " deveria passar");
      assertEquals(200, resposta.getStatus(), caminho);
    }

    verify(sessoes, never()).validar(any());
  }

  @Test void preflightEForaDaApiTambemPassam() throws Exception {
    var chamou = new AtomicBoolean(false);
    filtro.doFilter(
      requisicao("OPTIONS", "/api/colaboradores", null),
      new MockHttpServletResponse(),
      cadeia(chamou)
    );
    assertTrue(chamou.get());

    chamou.set(false);
    filtro.doFilter(
      requisicao("GET", "/index.html", null),
      new MockHttpServletResponse(),
      cadeia(chamou)
    );
    assertTrue(chamou.get());
  }

  @Test void semTokenRetorna401SemChamarACadeia() throws Exception {
    var chamou = new AtomicBoolean(false);
    var resposta = new MockHttpServletResponse();

    filtro.doFilter(requisicao("GET", "/api/colaboradores", null), resposta, cadeia(chamou));

    assertFalse(chamou.get());
    assertEquals(401, resposta.getStatus());
    assertTrue(resposta.getContentAsString().contains("Sessão ausente ou expirada"));
  }

  @Test void tokenInvalidoOuExpiradoRetorna401() throws Exception {
    when(sessoes.validar("expirado")).thenReturn(Optional.empty());

    var resposta = new MockHttpServletResponse();
    filtro.doFilter(
      requisicao("GET", "/api/colaboradores", "Bearer expirado"),
      resposta,
      cadeia(new AtomicBoolean(false))
    );

    assertEquals(401, resposta.getStatus());
    verify(sessoes).validar("expirado");
  }

  @Test void tokenValidoDisponibilizaSessaoDuranteAChamadaELimpraDepois() throws Exception {
    var sessao = new UsuarioSessao(1, "ana", "Ana Souza", "Administrador TST", Set.of("sgst_epis"));
    when(sessoes.validar("valido")).thenReturn(Optional.of(sessao));

    var durante = new AtomicReference<Optional<UsuarioSessao>>();
    var requisicao = requisicao("GET", "/api/colaboradores", "Bearer valido");

    filtro.doFilter(requisicao, new MockHttpServletResponse(), (req, res) -> {
      durante.set(ContextoUsuario.atual());
      assertSame(sessao, req.getAttribute("usuarioSessao"));
    });

    assertTrue(durante.get().isPresent());
    assertEquals("ana", durante.get().get().login());
    assertTrue(ContextoUsuario.atual().isEmpty(), "contexto deveria ser limpo no finally");
  }

  private MockHttpServletRequest requisicao(String metodo, String caminho, String autorizacao) {
    var requisicao = new MockHttpServletRequest(metodo, caminho);
    if (autorizacao != null) {
      requisicao.addHeader("Authorization", autorizacao);
    }
    return requisicao;
  }

  private FilterChain cadeia(AtomicBoolean chamou) {
    return (req, res) -> chamou.set(true);
  }
}
