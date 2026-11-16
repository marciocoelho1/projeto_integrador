package br.com.senac.sgsst.security;

import java.util.Set;

/** Usuário da sessão autenticada, disponível para os controllers e para a auditoria. */
public record UsuarioSessao(
  Integer id,
  String login,
  String nomeCompleto,
  String grupo,
  Set<String> modulos
) {
  public boolean possuiModulo(String chave) {
    return modulos != null && modulos.contains(chave);
  }
}
