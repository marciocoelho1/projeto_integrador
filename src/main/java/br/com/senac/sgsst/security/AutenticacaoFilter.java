package br.com.senac.sgsst.security;

import br.com.senac.sgsst.service.SessaoService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Optional;
import java.util.Set;

/**
 * Exige sessão válida (header Authorization: Bearer <token>) em /api/**, exceto nas rotas de
 * entrada e no health. A sessão do request fica em ContextoUsuario (usada pelos controllers e
 * serviços) e no atributo "usuarioSessao" do request.
 */
@Component
public class AutenticacaoFilter extends OncePerRequestFilter {

  private static final Set<String> ROTAS_LIVRES = Set.of(
    "/api/health",
    "/api/auth/login",
    "/api/auth/bootstrap",
    "/api/auth/recuperar-senha",
    "/api/auth/redefinir-senha"
  );

  private final SessaoService sessoes;

  public AutenticacaoFilter(SessaoService sessoes) {
    this.sessoes = sessoes;
  }

  @Override
  protected void doFilterInternal(
    HttpServletRequest requisicao,
    HttpServletResponse resposta,
    FilterChain cadeia
  ) throws ServletException, IOException {
    if (!exigeSessao(requisicao)) {
      cadeia.doFilter(requisicao, resposta);
      return;
    }

    Optional<UsuarioSessao> sessao = token(requisicao)
      .flatMap(sessoes::validar);

    if (sessao.isEmpty()) {
      responderNaoAutorizado(resposta);
      return;
    }

    ContextoUsuario.definir(sessao.get());
    requisicao.setAttribute("usuarioSessao", sessao.get());

    try {
      cadeia.doFilter(requisicao, resposta);
    } finally {
      ContextoUsuario.limpar();
    }
  }

  private boolean exigeSessao(HttpServletRequest requisicao) {
    String caminho = requisicao.getRequestURI();
    return "OPTIONS".equalsIgnoreCase(requisicao.getMethod()) == false
      && caminho.startsWith("/api/")
      && !ROTAS_LIVRES.contains(caminho);
  }

  private Optional<String> token(HttpServletRequest requisicao) {
    String cabecalho = requisicao.getHeader("Authorization");
    if (cabecalho == null || !cabecalho.startsWith("Bearer ")) {
      return Optional.empty();
    }
    String valor = cabecalho.substring("Bearer ".length()).trim();
    return valor.isEmpty() ? Optional.empty() : Optional.of(valor);
  }

  private void responderNaoAutorizado(HttpServletResponse resposta)
    throws IOException {
    resposta.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
    resposta.setContentType("application/json");
    resposta.setCharacterEncoding(StandardCharsets.UTF_8.name());
    resposta.getWriter().write(
      "{\"mensagem\":\"Sessão ausente ou expirada. Entre novamente.\"}"
    );
  }
}
