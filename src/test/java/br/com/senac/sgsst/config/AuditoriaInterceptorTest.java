package br.com.senac.sgsst.config;

import br.com.senac.sgsst.security.ContextoUsuario;
import br.com.senac.sgsst.security.UsuarioSessao;
import br.com.senac.sgsst.service.AuditoriaService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class AuditoriaInterceptorTest {

  final AuditoriaService auditoria = mock(AuditoriaService.class);
  final AuditoriaInterceptor interceptor = new AuditoriaInterceptor(auditoria);

  @AfterEach void limparContexto() { ContextoUsuario.limpar(); }

  @Test void postEmApiRegistraCriacaoComStatusDaResposta() {
    var resposta = new MockHttpServletResponse();
    resposta.setStatus(201);

    interceptor.afterCompletion(
      requisicao("POST", "/api/colaboradores"), resposta, new Object(), null
    );

    verify(auditoria).registrar(
      null, null, "colaboradores", "CRIACAO",
      "POST /api/colaboradores (201)", "POST", "/api/colaboradores", 201
    );
  }

  @Test void putEDeleteMapeiamEdicaoEExclusao() {
    var requisicaoPut = requisicao("PUT", "/api/epis/5");
    interceptor.afterCompletion(requisicaoPut, new MockHttpServletResponse(), new Object(), null);

    interceptor.afterCompletion(
      requisicao("DELETE", "/api/epis/5"), new MockHttpServletResponse(), new Object(), null
    );

    verify(auditoria).registrar(
      null, null, "epis", "EDICAO",
      "PUT /api/epis/5 (200)", "PUT", "/api/epis/5", 200
    );
    verify(auditoria).registrar(
      null, null, "epis", "EXCLUSAO",
      "DELETE /api/epis/5 (200)", "DELETE", "/api/epis/5", 200
    );
  }

  @Test void usaUsuarioDaSessaoQuandoExiste() {
    ContextoUsuario.definir(new UsuarioSessao(
      3, "ana", "Ana Souza", "Administrador TST", Set.of()
    ));

    var resposta = new MockHttpServletResponse();
    resposta.setStatus(200);
    interceptor.afterCompletion(requisicao("POST", "/api/epis"), resposta, new Object(), null);

    verify(auditoria).registrar(
      3, "Ana Souza", "epis", "CRIACAO",
      "POST /api/epis (200)", "POST", "/api/epis", 200
    );
  }

  @Test void loginRegistraAcessoInclusiveComFalhaDeCredencial() {
    var sucesso = new MockHttpServletResponse();
    sucesso.setStatus(200);
    interceptor.afterCompletion(requisicao("POST", "/api/auth/login"), sucesso, new Object(), null);

    var falha = new MockHttpServletResponse();
    falha.setStatus(401);
    interceptor.afterCompletion(requisicao("POST", "/api/auth/login"), falha, new Object(), null);

    verify(auditoria).registrar(
      null, null, "auth", "ACESSO",
      "POST /api/auth/login (200)", "POST", "/api/auth/login", 200
    );
    verify(auditoria).registrar(
      null, null, "auth", "ACESSO",
      "POST /api/auth/login (401)", "POST", "/api/auth/login", 401
    );
  }

  @Test void getNaoRegistraAuditoria() {
    for (String caminho : new String[]{
      "/api/colaboradores",
      "/api/chamados",
      "/api/auditoria"
    }) {
      interceptor.afterCompletion(
        requisicao("GET", caminho), new MockHttpServletResponse(), new Object(), null
      );
    }

    verifyNoInteractions(auditoria);
  }

  @Test void healthENaoApiNaoRegistram() {
    interceptor.afterCompletion(
      requisicao("GET", "/api/health"), new MockHttpServletResponse(), new Object(), null
    );
    interceptor.afterCompletion(
      requisicao("POST", "/index.html"), new MockHttpServletResponse(), new Object(), null
    );

    verifyNoInteractions(auditoria);
  }

  @Test void falhaDoServicoDeAuditoriaNaoPropaga() {
    doThrow(new RuntimeException("banco indisponível"))
      .when(auditoria)
      .registrar(any(), any(), any(), any(), any(), any(), any(), anyInt());

    assertDoesNotThrow(() -> interceptor.afterCompletion(
      requisicao("POST", "/api/colaboradores"),
      new MockHttpServletResponse(),
      new Object(),
      null
    ));
  }

  private MockHttpServletRequest requisicao(String metodo, String caminho) {
    return new MockHttpServletRequest(metodo, caminho);
  }
}
