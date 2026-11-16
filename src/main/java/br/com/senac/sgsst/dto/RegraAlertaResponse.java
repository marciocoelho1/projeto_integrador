package br.com.senac.sgsst.dto;

import br.com.senac.sgsst.entity.RegraAlerta;

public record RegraAlertaResponse(
  String codigo,
  String nomeRegra,
  String descricaoRegra,
  Boolean ativa
) {
  public static RegraAlertaResponse from(RegraAlerta regra) {
    return new RegraAlertaResponse(
      regra.getCodigo(),
      regra.getNomeRegra(),
      regra.getDescricaoRegra(),
      regra.getAtiva()
    );
  }
}
