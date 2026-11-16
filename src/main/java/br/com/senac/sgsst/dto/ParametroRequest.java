package br.com.senac.sgsst.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ParametroRequest(
  @NotBlank(message = "Informe o valor do parâmetro.")
  @Size(max = 255, message = "Valor: máximo de 255 caracteres.")
  String valor
) {
  public ParametroRequest {
    valor = valor == null ? null : valor.trim();
  }
}
