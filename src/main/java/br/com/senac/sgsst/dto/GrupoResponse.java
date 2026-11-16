package br.com.senac.sgsst.dto;

import br.com.senac.sgsst.entity.GrupoAcesso;
import java.util.List;

public record GrupoResponse(
  Integer id,
  String nomenclatura,
  String finalidade,
  List<String> modulos
) {
  public static GrupoResponse from(GrupoAcesso grupo) {
    return new GrupoResponse(
      grupo.getId(),
      grupo.getNomenclatura(),
      grupo.getFinalidade(),
      grupo.getModuloChaves().stream().sorted().toList()
    );
  }
}
