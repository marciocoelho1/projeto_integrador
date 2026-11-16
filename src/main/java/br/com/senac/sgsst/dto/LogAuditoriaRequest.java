package br.com.senac.sgsst.dto;
import jakarta.validation.constraints.*;
/** Lançamento manual de auditoria (POST /api/auditoria). Os IDs e metadados do request ficam a cargo do serviço. */
public record LogAuditoriaRequest(
  @Size(max = 150) String usuario,
  @NotBlank @Size(max = 60) String modulo,
  @NotBlank @Pattern(regexp = "CRIACAO|EDICAO|EXCLUSAO|ACESSO|ALERTA") String acao,
  @NotBlank @Size(max = 300) String descricao
) {
  public LogAuditoriaRequest {
    usuario = limpar(usuario);
    modulo = limpar(modulo);
    acao = limpar(acao);
    descricao = limpar(descricao);
  }
  private static String limpar(String value) { return value == null ? null : value.trim(); }
}
