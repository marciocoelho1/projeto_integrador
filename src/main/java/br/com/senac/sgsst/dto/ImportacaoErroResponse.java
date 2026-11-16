package br.com.senac.sgsst.dto;

/**
 * Erro de importação referente a uma única linha da planilha.
 *
 * <p>A linha é 1-based e conta o cabeçalho como linha 1, ou seja, a primeira
 * linha de dados é a linha 2 — o mesmo número que o usuário vê na planilha.</p>
 */
public record ImportacaoErroResponse(
  int linha,
  String mensagem
) {
}
