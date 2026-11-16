package br.com.senac.sgsst.dto;
import br.com.senac.sgsst.entity.CargoTreinamento;
public record CargoTreinamentoResponse(
  Integer id,
  Integer treinamentoId,
  String treinamento,
  String nr,
  Boolean obrigatorio
) {
  public static CargoTreinamentoResponse from(CargoTreinamento entity) {
    var treinamento = entity.getTreinamento();
    return new CargoTreinamentoResponse(
      entity.getId(),
      treinamento == null ? null : treinamento.getId(),
      treinamento == null ? null : treinamento.getNome(),
      treinamento == null ? null : treinamento.getNr(),
      entity.getObrigatorio()
    );
  }
}
