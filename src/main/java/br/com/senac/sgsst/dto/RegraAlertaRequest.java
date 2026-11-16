package br.com.senac.sgsst.dto;

import jakarta.validation.constraints.NotNull;

public record RegraAlertaRequest(
  @NotNull(message = "Informe se a regra fica ativa.")
  Boolean ativa
) {
}
