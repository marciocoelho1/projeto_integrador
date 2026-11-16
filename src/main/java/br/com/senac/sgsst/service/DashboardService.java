package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.AlertaIndicador;
import br.com.senac.sgsst.dto.DashboardIndicadoresResponse;
import br.com.senac.sgsst.dto.ResumoCertificacoes;
import br.com.senac.sgsst.dto.ResumoColaboradores;
import br.com.senac.sgsst.dto.ResumoEpis;
import br.com.senac.sgsst.dto.ResumoTreinamentos;
import br.com.senac.sgsst.repository.CertificacaoRepository;
import br.com.senac.sgsst.repository.ChamadoRepository;
import br.com.senac.sgsst.repository.ColaboradorRepository;
import br.com.senac.sgsst.repository.ColaboradorTreinamentoRepository;
import br.com.senac.sgsst.repository.EpiEntregaRepository;
import br.com.senac.sgsst.repository.EpiRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Indicadores reais do dashboard: tudo é contado no banco a partir das tabelas já integradas
 * (colaboradores, epis, epi_entregas, certificacoes, colaborador_treinamentos e chamados).
 * Nenhum número é fixo — se um recurso não tem dado, o indicador volta zerado.
 *
 * <p>Os alertas do card "Atenção Requerida" são derivados dos mesmos números, com criticidade
 * {@code alta} para prazo já estourado e {@code media} para o que está dentro da janela de
 * {@value #JANELA_ALERTA_DIAS} dias.</p>
 */
@Service
@Transactional(readOnly = true)
public class DashboardService {
  /** Janela de "próximo do vencimento", a mesma ideia usada nas reciclagens. */
  public static final int JANELA_ALERTA_DIAS = 30;

  private static final String STATUS_ATIVO = "Ativo";
  private static final String STATUS_INATIVO = "Inativo";
  private static final String STATUS_AFASTADO = "Afastado";
  private static final String VINCULO_CONCLUIDO = "Concluído";
  private static final String CHAMADO_EM_ANDAMENTO = "Em andamento";

  private final ColaboradorRepository colaboradores;
  private final EpiRepository epis;
  private final EpiEntregaRepository entregas;
  private final CertificacaoRepository certificacoes;
  private final ColaboradorTreinamentoRepository vinculos;
  private final ChamadoRepository chamados;

  public DashboardService(
    ColaboradorRepository colaboradores,
    EpiRepository epis,
    EpiEntregaRepository entregas,
    CertificacaoRepository certificacoes,
    ColaboradorTreinamentoRepository vinculos,
    ChamadoRepository chamados
  ) {
    this.colaboradores = colaboradores;
    this.epis = epis;
    this.entregas = entregas;
    this.certificacoes = certificacoes;
    this.vinculos = vinculos;
    this.chamados = chamados;
  }

  public DashboardIndicadoresResponse indicadores() {
    return indicadores(LocalDate.now());
  }

  /**
   * Sobrecarga com a data de referência: os testes passam uma data fixa em vez de depender do
   * relógio da máquina, como faz o {@link ReciclagemService}.
   */
  DashboardIndicadoresResponse indicadores(LocalDate hoje) {
    LocalDate limite = hoje.plusDays(JANELA_ALERTA_DIAS);

    ResumoColaboradores resumoColaboradores = new ResumoColaboradores(
      colaboradores.count(),
      colaboradores.countByStatus(STATUS_ATIVO),
      colaboradores.countByStatus(STATUS_INATIVO),
      colaboradores.countByStatus(STATUS_AFASTADO)
    );

    long certificacoesVencidas = certificacoes.countByValidadeLessThan(hoje);
    long certificacoesAtivas = certificacoes.countByValidadeGreaterThanEqual(hoje);
    ResumoCertificacoes resumoCertificacoes = new ResumoCertificacoes(
      certificacoesVencidas + certificacoesAtivas,
      certificacoesAtivas,
      certificacoesVencidas,
      certificacoes.countByValidadeBetween(hoje, limite)
    );

    long epiVencidos = epis.somarQuantidadesComValidadeAnterior(hoje);
    long epiProximoVencimento = epis.somarQuantidadesComValidadeEntre(hoje, limite);
    ResumoEpis resumoEpis = new ResumoEpis(
      epis.somarQuantidades(),
      epiProximoVencimento,
      epiVencidos,
      entregas.somarQuantidadesNoPeriodo(hoje.minusDays(JANELA_ALERTA_DIAS), hoje),
      epis.count()
    );

    long vinculosTotal = vinculos.count();
    long vinculosConcluidos = vinculos.countByStatus(VINCULO_CONCLUIDO);
    long vinculosVencidos = vinculos.countByValidadeLessThan(hoje);
    long vinculosPendentes = Math.max(0, vinculosTotal - vinculosConcluidos) + vinculosVencidos;
    long vinculosEmDia = Math.max(0, vinculosConcluidos - vinculosVencidos);
    ResumoTreinamentos resumoTreinamentos = new ResumoTreinamentos(
      vinculosConcluidos,
      vinculosPendentes,
      vinculosVencidos,
      vinculosTotal,
      vinculosTotal == 0 ? 0 : (int) Math.round(vinculosEmDia * 100.0 / vinculosTotal)
    );

    long chamadosEmAndamento = chamados.countByStatus(CHAMADO_EM_ANDAMENTO);

    return new DashboardIndicadoresResponse(
      resumoColaboradores,
      resumoCertificacoes,
      resumoEpis,
      resumoTreinamentos,
      alertas(
        epiVencidos,
        epiProximoVencimento,
        certificacoesVencidas,
        resumoCertificacoes.vencendoEm30Dias(),
        vinculosVencidos,
        Math.max(0, vinculosTotal - vinculosConcluidos),
        chamadosEmAndamento
      ),
      OffsetDateTime.now()
    );
  }

  /** Alertas derivados dos indicadores; sem pendência, devolve um informativo para o card não ficar vazio. */
  private List<AlertaIndicador> alertas(
    long epiVencidos,
    long epiProximoVencimento,
    long certificacoesVencidas,
    long certificacoesVencendo,
    long vinculosVencidos,
    long vinculosPendentes,
    long chamadosEmAndamento
  ) {
    List<AlertaIndicador> alertas = new ArrayList<>();

    if (epiVencidos > 0) {
      alertas.add(new AlertaIndicador(
        "EPI",
        epiVencidos + " unidade(s) de EPI com CA vencido no estoque.",
        "alta"
      ));
    }

    if (certificacoesVencidas > 0) {
      alertas.add(new AlertaIndicador(
        "Certificação",
        certificacoesVencidas + " certificação(ões) de colaborador vencida(s).",
        "alta"
      ));
    }

    if (vinculosVencidos > 0) {
      alertas.add(new AlertaIndicador(
        "Treinamento",
        vinculosVencidos + " treinamento(s) de colaborador com reciclagem vencida.",
        "alta"
      ));
    }

    if (epiProximoVencimento > 0) {
      alertas.add(new AlertaIndicador(
        "EPI",
        epiProximoVencimento + " unidade(s) de EPI vencem nos próximos " + JANELA_ALERTA_DIAS + " dias.",
        "media"
      ));
    }

    if (certificacoesVencendo > 0) {
      alertas.add(new AlertaIndicador(
        "Certificação",
        certificacoesVencendo + " certificação(ões) vencem em até " + JANELA_ALERTA_DIAS + " dias.",
        "media"
      ));
    }

    if (vinculosPendentes > 0) {
      alertas.add(new AlertaIndicador(
        "Treinamento",
        vinculosPendentes + " treinamento(s) obrigatório(s) ainda pendente(s).",
        "media"
      ));
    }

    if (chamadosEmAndamento > 0) {
      alertas.add(new AlertaIndicador(
        "Suporte",
        chamadosEmAndamento + " chamado(s) de suporte em andamento.",
        "media"
      ));
    }

    if (alertas.isEmpty()) {
      alertas.add(new AlertaIndicador("Geral", "Nenhuma pendência crítica no momento.", "baixa"));
    }

    return alertas.stream()
      .sorted(Comparator.comparingInt(alerta -> pesoDaCriticidade(alerta.criticidade())))
      .toList();
  }

  private int pesoDaCriticidade(String criticidade) {
    return switch (criticidade) {
      case "alta" -> 0;
      case "media" -> 1;
      default -> 2;
    };
  }
}
