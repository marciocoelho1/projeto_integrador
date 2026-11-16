package br.com.senac.sgsst.dto;
import br.com.senac.sgsst.entity.Chamado;
import java.time.Instant;
public record ChamadoResponse(
  Integer id,
  String tipo,
  String descricao,
  Integer usuarioId,
  String solicitante,
  String status,
  Instant abertoEm,
  Instant concluidoEm
) {
  public static ChamadoResponse from(Chamado entity) {
    return new ChamadoResponse(
      entity.getId(),
      entity.getTipo(),
      entity.getDescricao(),
      entity.getUsuario() == null ? null : entity.getUsuario().getId(),
      entity.getSolicitante(),
      entity.getStatus(),
      entity.getAbertoEm(),
      entity.getConcluidoEm()
    );
  }
}
