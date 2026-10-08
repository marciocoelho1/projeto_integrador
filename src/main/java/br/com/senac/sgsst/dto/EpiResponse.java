package br.com.senac.sgsst.dto;
import br.com.senac.sgsst.entity.Epi;
import java.time.LocalDate;
public record EpiResponse(
  Integer id,
  String descricao,
  String ca,
  LocalDate inclusao,
  LocalDate validade,
  Integer quantidade
) {
  public static EpiResponse from(Epi entity) {
    return new EpiResponse(entity.getId(), entity.getDescricao(), entity.getCa(), entity.getInclusao(), entity.getValidade(), entity.getQuantidade());
  }
}
