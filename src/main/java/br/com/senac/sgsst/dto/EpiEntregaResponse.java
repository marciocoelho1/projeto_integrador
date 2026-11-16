package br.com.senac.sgsst.dto;
import br.com.senac.sgsst.entity.EpiEntrega;
import java.time.Instant;
import java.time.LocalDate;
public record EpiEntregaResponse(
  Integer id,
  Integer colaboradorId,
  String colaborador,
  String matricula,
  Integer epiId,
  String epi,
  String ca,
  Integer quantidade,
  LocalDate dataEntrega,
  String assinatura,
  Instant registradoEm
) {
  /** O campo ca é o CA gravado no ato da entrega (ca_no_ato), não o CA atual do EPI. */
  public static EpiEntregaResponse from(EpiEntrega entity) {
    return new EpiEntregaResponse(
      entity.getId(),
      entity.getColaborador().getId(),
      entity.getColaborador().getNome(),
      entity.getColaborador().getMatricula(),
      entity.getEpi().getId(),
      entity.getEpi().getDescricao(),
      entity.getCaNoAto(),
      entity.getQuantidade(),
      entity.getDataEntrega(),
      entity.getAssinatura(),
      entity.getRegistradoEm()
    );
  }
}
