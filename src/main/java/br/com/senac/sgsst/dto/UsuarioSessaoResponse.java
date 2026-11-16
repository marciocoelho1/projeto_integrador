package br.com.senac.sgsst.dto;

import br.com.senac.sgsst.security.UsuarioSessao;
import java.util.List;

public record UsuarioSessaoResponse(
  Integer id,
  String login,
  String nomeCompleto,
  String grupo,
  List<String> modulos
) {
  public static UsuarioSessaoResponse from(UsuarioSessao sessao) {
    return new UsuarioSessaoResponse(
      sessao.id(),
      sessao.login(),
      sessao.nomeCompleto(),
      sessao.grupo(),
      sessao.modulos() == null ? List.of() : List.copyOf(sessao.modulos())
    );
  }
}
