package br.com.senac.sgsst.dto;
import jakarta.validation.constraints.*;
public record CargoTreinamentoItemRequest(
  @NotNull Integer treinamentoId,
  Boolean obrigatorio
) {
  public boolean obrigatorioEfetivo() { return obrigatorio == null || obrigatorio; }
}
