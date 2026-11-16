package br.com.senac.sgsst.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record LoginRequest(
  @NotBlank(message = "Informe o usuário.") @Size(max = 60) String login,
  @NotBlank(message = "Informe a senha.") @Size(max = 72) String senha
) {
  public LoginRequest {
    login = login == null ? null : login.trim().toLowerCase();
  }
}
