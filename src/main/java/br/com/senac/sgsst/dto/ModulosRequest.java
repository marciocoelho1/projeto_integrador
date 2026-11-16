package br.com.senac.sgsst.dto;

import java.util.List;

/** Corpo de PUT /api/grupos/{id}/modulos: a matriz de acessos do grupo. */
public record ModulosRequest(List<String> modulos) {
  public ModulosRequest {
    modulos = modulos == null ? List.of() : List.copyOf(modulos);
  }
}
