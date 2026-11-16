package br.com.senac.sgsst.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RecuperarSenhaRequest(
  @NotBlank(message = "Informe o usuário ou o e-mail cadastrado.")
  @Size(max = 180)
  String login
) {
  public RecuperarSenhaRequest {
    login = login == null ? null : login.trim().toLowerCase();
  }
}
