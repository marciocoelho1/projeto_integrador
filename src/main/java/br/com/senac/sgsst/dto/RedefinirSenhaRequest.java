package br.com.senac.sgsst.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RedefinirSenhaRequest(
  @NotBlank(message = "Informe o código de redefinição.")
  @Size(max = 64)
  String token,

  @NotBlank(message = "Informe a nova senha.")
  @Size(min = 6, max = 72, message = "A senha deve ter de 6 a 72 caracteres.")
  String senha
) {
  public RedefinirSenhaRequest {
    token = token == null ? null : token.trim();
  }
}
