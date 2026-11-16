package br.com.senac.sgsst.dto;

/**
 * Certificações de colaborador (tabela {@code certificacoes}) por situação da data de validade:
 * {@code ativas} (validade hoje ou no futuro), {@code vencidas} (validade no passado) e
 * {@code vencendoEm30Dias} (subconjunto das ativas que vencem na janela de alerta).
 */
public record ResumoCertificacoes(
  long total,
  long ativas,
  long vencidas,
  long vencendoEm30Dias
) {
}
