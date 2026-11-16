package br.com.senac.sgsst.dto;
import br.com.senac.sgsst.entity.LogAuditoria;
import java.time.Instant;
public record LogAuditoriaResponse(
  Integer id,
  Instant dataHora,
  Integer usuarioId,
  String usuario,
  String modulo,
  String acao,
  String descricao,
  String metodo,
  String caminho,
  Integer statusHttp
) {
  public static LogAuditoriaResponse from(LogAuditoria entity) {
    return new LogAuditoriaResponse(
      entity.getId(),
      entity.getDataHora(),
      entity.getUsuario() == null ? null : entity.getUsuario().getId(),
      entity.getUsuarioNome(),
      entity.getModulo(),
      entity.getAcao(),
      entity.getDescricao(),
      entity.getMetodo(),
      entity.getCaminho(),
      entity.getStatusHttp()
    );
  }
}
