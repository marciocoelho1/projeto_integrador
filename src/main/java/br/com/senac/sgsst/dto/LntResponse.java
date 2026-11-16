package br.com.senac.sgsst.dto;
import br.com.senac.sgsst.entity.Cargo;
import java.util.List;
public record LntResponse(
  Integer id,
  String cargo,
  String setor,
  String status,
  List<CargoTreinamentoResponse> treinamentos
) {
  public static LntResponse from(Cargo cargo, List<CargoTreinamentoResponse> treinamentos) {
    return new LntResponse(cargo.getId(), cargo.getNome(), cargo.getSetor(), cargo.getStatus(), treinamentos);
  }
}
