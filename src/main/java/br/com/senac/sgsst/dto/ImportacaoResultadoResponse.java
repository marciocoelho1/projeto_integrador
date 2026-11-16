package br.com.senac.sgsst.dto;

import java.util.List;

/**
 * Resumo de uma importação em massa.
 *
 * @param total      quantidade de linhas recebidas no lote
 * @param importados linhas gravadas com sucesso
 * @param ignorados  linhas descartadas ({@code total - importados})
 * @param erros      detalhamento por linha (mesma ordem das linhas recebidas)
 */
public record ImportacaoResultadoResponse(
  int total,
  int importados,
  int ignorados,
  List<ImportacaoErroResponse> erros
) {
}
