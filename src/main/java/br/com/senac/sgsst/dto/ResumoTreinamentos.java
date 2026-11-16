package br.com.senac.sgsst.dto;

/**
 * Progresso dos vínculos colaborador × treinamento (tabela {@code colaborador_treinamentos}).
 *
 * <p>{@code concluidos} são os vínculos com status {@code Concluído}; {@code vencidos} são os
 * vínculos cuja validade já passou (reciclagem em atraso, normalmente um subconjunto dos
 * concluídos). {@code pendentes} é o que falta fazer: vínculos não concluídos mais os concluídos
 * já vencidos. {@code porcentagem} é a fatia em dia ({@code concluidos - vencidos} sobre
 * {@code total}), arredondada.</p>
 */
public record ResumoTreinamentos(
  long concluidos,
  long pendentes,
  long vencidos,
  long total,
  int porcentagem
) {
}
