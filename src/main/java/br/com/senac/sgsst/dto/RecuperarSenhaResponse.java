package br.com.senac.sgsst.dto;

import java.time.Instant;

/**
 * Redefinição pendente, listada para o administrador entregar o código ao usuário.
 * Enquanto o projeto não tiver SMTP, este é o único caminho para o código chegar ao usuário.
 */
public record RecuperarSenhaResponse(
  Integer id,
  Integer usuarioId,
  String login,
  String nomeCompleto,
  String email,
  String token,
  Instant criadaEm,
  Instant expiraEm
) {
}
