package br.com.senac.sgsst.dto;
import br.com.senac.sgsst.entity.Treinamento;
public record TreinamentoResponse(
  Integer id,
  String codigo,
  String nome,
  String classificacao,
  String nr,
  String cargaHoraria,
  Integer validadeMeses,
  String status
) {
  public static TreinamentoResponse from(Treinamento entity) {
    return new TreinamentoResponse(entity.getId(), entity.getCodigo(), entity.getNome(), entity.getClassificacao(), entity.getNr(), entity.getCargaHoraria(), entity.getValidadeMeses(), entity.getStatus());
  }
}
