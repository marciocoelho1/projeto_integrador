package br.com.senac.sgsst.dto;

import br.com.senac.sgsst.entity.Parametro;

public record ParametroResponse(String chave, String valor, String descricao) {
  public static ParametroResponse from(Parametro parametro) {
    return new ParametroResponse(
      parametro.getChave(),
      parametro.getValor(),
      parametro.getDescricao()
    );
  }
}
