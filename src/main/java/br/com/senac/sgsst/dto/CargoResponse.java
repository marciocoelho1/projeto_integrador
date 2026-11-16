package br.com.senac.sgsst.dto;
import br.com.senac.sgsst.entity.Cargo;
public record CargoResponse(
  Integer id,
  String nome,
  String setor,
  String status
) {
  public static CargoResponse from(Cargo entity) {
    return new CargoResponse(entity.getId(), entity.getNome(), entity.getSetor(), entity.getStatus());
  }
}
