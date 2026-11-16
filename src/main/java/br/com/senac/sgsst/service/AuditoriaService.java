package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.LogAuditoriaRequest;
import br.com.senac.sgsst.dto.LogAuditoriaResponse;
import br.com.senac.sgsst.entity.LogAuditoria;
import br.com.senac.sgsst.exception.RequisicaoInvalidaException;
import br.com.senac.sgsst.repository.LogAuditoriaRepository;
import br.com.senac.sgsst.repository.UsuarioRepository;
import br.com.senac.sgsst.security.ContextoUsuario;
import br.com.senac.sgsst.security.UsuarioSessao;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Comparator;
import java.util.List;
import java.util.Set;

/**
 * Auditoria persistida (item 8). O AuditoriaInterceptor chama registrar(...) a cada escrita em
 * /api/**; a tela de logs usa listar(...). A gravação nunca deve derrubar a requisição do usuário,
 * então quem chama envolve em try/catch (o interceptor já faz isso).
 */
@Service
@Transactional(readOnly = true)
public class AuditoriaService {

  private static final Set<String> ACOES_VALIDAS =
    Set.of("CRIACAO", "EDICAO", "EXCLUSAO", "ACESSO", "ALERTA");

  private final LogAuditoriaRepository repository;
  private final UsuarioRepository usuarios;

  public AuditoriaService(
    LogAuditoriaRepository repository,
    UsuarioRepository usuarios
  ) {
    this.repository = repository;
    this.usuarios = usuarios;
  }

  /** Registro completo, usado pelo interceptor. */
  @Transactional
  public LogAuditoriaResponse registrar(
    Integer usuarioId,
    String usuarioNome,
    String modulo,
    String acao,
    String descricao,
    String metodo,
    String caminho,
    int statusHttp
  ) {
    if (acao == null || !ACOES_VALIDAS.contains(acao)) {
      throw new RequisicaoInvalidaException("Ação de auditoria inválida.");
    }

    LogAuditoria entity = new LogAuditoria();
    entity.setDataHora(Instant.now());
    entity.setUsuario(usuarioId == null ? null : usuarios.getReferenceById(usuarioId));
    entity.setUsuarioNome(limitar(usuarioNome, 150));
    entity.setModulo(limitar(modulo, 60));
    entity.setAcao(acao);
    entity.setDescricao(limitar(descricao, 300));
    entity.setMetodo(limitar(metodo, 10));
    entity.setCaminho(limitar(caminho, 300));
    entity.setStatusHttp(statusHttp);

    return LogAuditoriaResponse.from(repository.saveAndFlush(entity));
  }

  /**
   * Variante simples do registro manual (POST /api/auditoria): completa usuário e metadados a
   * partir da sessão atual.
   */
  @Transactional
  public LogAuditoriaResponse registrar(
    String usuarioNome,
    String modulo,
    String acao,
    String descricao
  ) {
    var sessao = ContextoUsuario.atual();
    String nome = usuarioNome != null && !usuarioNome.isBlank()
      ? usuarioNome
      : sessao.map(UsuarioSessao::nomeCompleto).orElse(null);

    return registrar(
      sessao.map(UsuarioSessao::id).orElse(null),
      nome,
      modulo,
      acao,
      descricao,
      "MANUAL",
      "/api/auditoria",
      201
    );
  }

  public LogAuditoriaResponse registrar(LogAuditoriaRequest request) {
    return registrar(
      request.usuario(),
      request.modulo(),
      request.acao(),
      request.descricao()
    );
  }

  /**
   * Lista os logs mais recentes primeiro, filtrando por termo (usuário, módulo ou descrição,
   * sem diferenciar maiúsculas) e pelo intervalo de datas informado (início/fim inclusivos).
   */
  public List<LogAuditoriaResponse> listar(String termo, LocalDate inicio, LocalDate fim) {
    String alvo = termo == null ? "" : termo.trim().toLowerCase();

    return repository.findAll().stream()
      .filter(log -> alvo.isEmpty() || contem(log, alvo))
      .filter(log -> dentroDoPeriodo(log, inicio, fim))
      .sorted(Comparator.comparing(LogAuditoria::getDataHora).reversed())
      .map(LogAuditoriaResponse::from)
      .toList();
  }

  private boolean contem(LogAuditoria log, String alvo) {
    return texto(log.getUsuarioNome()).contains(alvo)
      || texto(log.getModulo()).contains(alvo)
      || texto(log.getDescricao()).contains(alvo);
  }

  private boolean dentroDoPeriodo(LogAuditoria log, LocalDate inicio, LocalDate fim) {
    if (inicio == null && fim == null) {
      return true;
    }

    LocalDate dia = LocalDate.ofInstant(log.getDataHora(), ZoneId.systemDefault());

    if (inicio != null && dia.isBefore(inicio)) {
      return false;
    }

    return fim == null || !dia.isAfter(fim);
  }

  private String texto(String valor) {
    return valor == null ? "" : valor.toLowerCase();
  }

  private String limitar(String valor, int tamanho) {
    if (valor == null) {
      return null;
    }
    return valor.length() <= tamanho ? valor : valor.substring(0, tamanho);
  }
}
