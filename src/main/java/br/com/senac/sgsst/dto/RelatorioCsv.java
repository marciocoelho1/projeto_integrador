package br.com.senac.sgsst.dto;

/**
 * Arquivo CSV pronto para download: {@code nomeArquivo} vira o {@code Content-Disposition} e
 * {@code conteudo} é o texto (já com BOM UTF-8) devolvido como corpo da resposta.
 */
public record RelatorioCsv(
  String nomeArquivo,
  String conteudo
) {
}
