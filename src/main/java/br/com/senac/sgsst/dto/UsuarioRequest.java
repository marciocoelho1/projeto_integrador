package br.com.senac.sgsst.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.util.Locale;

/**
 * senha é obrigatória no cadastro e opcional na edição; a obrigatoriedade do cadastro é conferida
 * no serviço (RequisicaoInvalidaException → 400), porque o mesmo record serve ao PUT.
 */
public record UsuarioRequest(

  @NotBlank(message = "Informe o nome completo.")
  @Size(max = 150, message = "Nome: máximo de 150 caracteres.")
  String nomeCompleto,

  @NotBlank(message = "Informe o usuário de acesso.")
  @Pattern(
    regexp = "[a-zA-Z0-9._-]{3,60}",
    message = "Usuário: de 3 a 60 caracteres, apenas letras, números, ponto, hífen e sublinhado."
  )
  String login,

  @NotBlank(message = "Informe o e-mail.")
  @Email(message = "Informe um e-mail válido.")
  @Size(max = 180, message = "E-mail: máximo de 180 caracteres.")
  String email,

  @NotBlank(message = "Informe o CPF.")
  @Pattern(regexp = "\\d{11}", message = "O CPF deve conter 11 dígitos.")
  String cpf,

  @NotNull(message = "Informe o grupo de acesso.")
  @Positive(message = "Grupo de acesso inválido.")
  Integer grupoId,

  @NotBlank(message = "Informe o status.")
  @Pattern(regexp = "Ativo|Inativo", message = "Status deve ser Ativo ou Inativo.")
  String status,

  @Size(min = 6, max = 72, message = "A senha deve ter de 6 a 72 caracteres.")
  String senha
) {

  public UsuarioRequest {
    nomeCompleto = limpar(nomeCompleto);
    login = minusculo(limpar(login));
    email = minusculo(limpar(email));
    cpf = cpf == null ? null : cpf.replaceAll("[.\\-\\s]", "");
    status = limpar(status);
    senha = senha == null || senha.isBlank() ? null : senha;
  }

  private static String limpar(String valor) {
    return valor == null ? null : valor.trim();
  }

  private static String minusculo(String valor) {
    return valor == null ? null : valor.toLowerCase(Locale.ROOT);
  }
}
