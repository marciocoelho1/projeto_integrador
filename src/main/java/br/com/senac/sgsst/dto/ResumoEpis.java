package br.com.senac.sgsst.dto;

/**
 * Estoque de EPIs. Todas as quantidades são em unidades de EPI, não em tipos de EPI cadastrados:
 *
 * <ul>
 *   <li>{@code emEstoque}: soma de {@code epis.quantidade} (saldo atual, já abatido pelas entregas);</li>
 *   <li>{@code proximoVencimento}: unidades cujo CA vence na janela de alerta (hoje até hoje+30);</li>
 *   <li>{@code vencidos}: unidades cujo CA já venceu;</li>
 *   <li>{@code entreguesUltimos30Dias}: unidades entregues a colaboradores nos últimos 30 dias;</li>
 *   <li>{@code totalTipos}: quantidade de EPIs cadastrados (linhas em {@code epis}).</li>
 * </ul>
 */
public record ResumoEpis(
  long emEstoque,
  long proximoVencimento,
  long vencidos,
  long entreguesUltimos30Dias,
  long totalTipos
) {
}
