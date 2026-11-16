package br.com.senac.sgsst.dto;

/**
 * Quadro de colaboradores. {@code total} é a soma de {@code ativos}, {@code inativos} e
 * {@code afastados} (os três status previstos em {@code colaboradores.status}).
 */
public record ResumoColaboradores(
  long total,
  long ativos,
  long inativos,
  long afastados
) {
}
