package br.com.senac.sgsst.dto;

import java.time.OffsetDateTime;
import java.util.List;

/**
 * Indicadores reais do dashboard, agregados no servidor a partir de colaboradores, EPIs, entregas
 * de EPI, certificações, vínculos colaborador × treinamento e chamados de suporte.
 *
 * <p>{@code geradoEm} é o instante do cálculo, para a tela conseguir mostrar a idade do número.</p>
 */
public record DashboardIndicadoresResponse(
  ResumoColaboradores colaboradores,
  ResumoCertificacoes certificacoes,
  ResumoEpis epis,
  ResumoTreinamentos treinamentos,
  List<AlertaIndicador> alertas,
  OffsetDateTime geradoEm
) {
}
