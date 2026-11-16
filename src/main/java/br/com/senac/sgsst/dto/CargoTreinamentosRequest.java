package br.com.senac.sgsst.dto;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.util.List;
public record CargoTreinamentosRequest(
  @NotNull @Valid List<CargoTreinamentoItemRequest> treinamentos
) {
  public CargoTreinamentosRequest {
    treinamentos = treinamentos == null ? null : List.copyOf(treinamentos);
  }
}
