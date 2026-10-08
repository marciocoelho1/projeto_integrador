package br.com.senac.sgsst.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record ColaboradorRequest(

  @NotBlank(message = "Informe a matrícula.")
  @Size(max = 30, message = "Matrícula: máximo de 30 caracteres.")
  String matricula,

  @NotBlank(message = "Informe o nome.")
  @Size(max = 150, message = "Nome: máximo de 150 caracteres.")
  String nome,

  @NotBlank(message = "Informe o CPF.")
  @Pattern(
    regexp = "\\d{11}",
    message = "O CPF deve conter 11 dígitos."
  )
  String cpf,

  @NotBlank(message = "Informe o e-mail.")
  @Email(message = "Informe um e-mail válido.")
  @Size(max = 180, message = "E-mail: máximo de 180 caracteres.")
  String email,

  @NotBlank(message = "Informe o cargo.")
  @Size(max = 120, message = "Cargo: máximo de 120 caracteres.")
  String cargo,

  @NotBlank(message = "Informe o setor.")
  @Size(max = 120, message = "Setor: máximo de 120 caracteres.")
  String setor,

  @NotBlank(message = "Informe o status.")
  @Pattern(
    regexp = "Ativo|Inativo|Afastado",
    message = "Status deve ser Ativo, Inativo ou Afastado."
  )
  String status
) {

  public ColaboradorRequest {
    matricula = limpar(matricula);
    nome = limpar(nome);
    cpf = cpf == null
      ? null
      : cpf.replaceAll("[.\\-\\s]", "");
    email = limpar(email);
    cargo = limpar(cargo);
    setor = limpar(setor);
    status = limpar(status);
  }

  private static String limpar(String valor) {
    return valor == null ? null : valor.trim();
  }
}
