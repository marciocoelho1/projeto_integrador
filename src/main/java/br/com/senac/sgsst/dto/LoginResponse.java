package br.com.senac.sgsst.dto;

import java.time.Instant;

public record LoginResponse(
  String token,
  Instant expiraEm,
  UsuarioSessaoResponse usuario
) {
}
