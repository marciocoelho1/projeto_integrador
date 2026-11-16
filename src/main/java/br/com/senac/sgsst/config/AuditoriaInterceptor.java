package br.com.senac.sgsst.config;

import br.com.senac.sgsst.security.ContextoUsuario;
import br.com.senac.sgsst.security.UsuarioSessao;
import br.com.senac.sgsst.service.AuditoriaService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * Captura automática de auditoria (item 8). Registra apenas as escritas (POST/PUT/DELETE) em
 * /api/**. A gravação acontece em afterCompletion para já conhecer o status HTTP final (inclusive
 * erros tratados, como o 401 do login com senha errada) e fica isolada em try/catch: uma falha de
 * auditoria nunca pode quebrar a requisição do usuário.
 */
@Component
public class AuditoriaInterceptor implements HandlerInterceptor {

  private static final Logger LOG = LoggerFactory.getLogger(AuditoriaInterceptor.class);
  private static final String API = "/api";

  private final AuditoriaService auditoria;

  public AuditoriaInterceptor(AuditoriaService auditoria) {
    this.auditoria = auditoria;
  }

  @Override
  public void afterCompletion(
    HttpServletRequest request,
    HttpServletResponse response,
    Object handler,
    Exception excecao
  ) {
    if (!deveRegistrar(request)) {
      return;
    }

    try {
      var sessao = ContextoUsuario.atual();
      String caminho = request.getRequestURI();
      String metodo = request.getMethod();
      String modulo = modulo(caminho);
      int status = response.getStatus();

      auditoria.registrar(
        sessao.map(UsuarioSessao::id).orElse(null),
        sessao.map(UsuarioSessao::nomeCompleto).orElse(null),
        modulo,
        acao(modulo, metodo),
        metodo + " " + caminho + " (" + status + ")",
        metodo,
        caminho,
        status
      );
    } catch (RuntimeException falha) {
      LOG.warn(
        "Falha ao registrar auditoria de {} {}",
        request.getMethod(),
        request.getRequestURI(),
        falha
      );
    }
  }

  private boolean deveRegistrar(HttpServletRequest request) {
    String metodo = request.getMethod();

    if (!"POST".equals(metodo) && !"PUT".equals(metodo) && !"DELETE".equals(metodo)) {
      return false;
    }

    return caminhoApi(request.getRequestURI());
  }

  private boolean caminhoApi(String caminho) {
    return caminho != null && (API.equals(caminho) || caminho.startsWith(API + "/"));
  }

  /** Primeiro segmento do caminho depois de /api (ex.: /api/colaboradores/5 -> colaboradores). */
  private String modulo(String caminho) {
    String[] partes = caminho.split("/");
    return partes.length > 2 ? partes[2] : "api";
  }

  private String acao(String modulo, String metodo) {
    if ("auth".equals(modulo)) {
      return "ACESSO";
    }

    return switch (metodo) {
      case "POST" -> "CRIACAO";
      case "PUT" -> "EDICAO";
      case "DELETE" -> "EXCLUSAO";
      default -> "ALERTA";
    };
  }
}
