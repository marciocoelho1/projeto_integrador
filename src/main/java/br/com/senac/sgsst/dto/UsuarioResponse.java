package br.com.senac.sgsst.dto;

import br.com.senac.sgsst.entity.Usuario;
import java.time.Instant;
import java.util.List;

public record UsuarioResponse(
  Integer id,
  String nomeCompleto,
  String login,
  String email,
  String cpf,
  Integer grupoId,
  String grupo,
  String status,
  List<String> modulos,
  Instant criadoEm
) {
  public static UsuarioResponse from(Usuario usuario) {
    return new UsuarioResponse(
      usuario.getId(),
      usuario.getNomeCompleto(),
      usuario.getLogin(),
      usuario.getEmail(),
      usuario.getCpf(),
      usuario.getGrupo().getId(),
      usuario.getGrupo().getNomenclatura(),
      usuario.getStatus(),
      List.copyOf(usuario.getGrupo().getModuloChaves()),
      usuario.getCriadoEm()
    );
  }
}
