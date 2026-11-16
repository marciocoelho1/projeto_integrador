package br.com.senac.sgsst.dto;

import br.com.senac.sgsst.entity.Modulo;

public record ModuloResponse(String chave, String titulo, String detalhe) {
  public static ModuloResponse from(Modulo modulo) {
    return new ModuloResponse(
      modulo.getChave(),
      modulo.getTitulo(),
      modulo.getDetalhe()
    );
  }
}
