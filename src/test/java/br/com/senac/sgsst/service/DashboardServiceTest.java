package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.DashboardIndicadoresResponse;
import br.com.senac.sgsst.repository.CertificacaoRepository;
import br.com.senac.sgsst.repository.ChamadoRepository;
import br.com.senac.sgsst.repository.ColaboradorRepository;
import br.com.senac.sgsst.repository.ColaboradorTreinamentoRepository;
import br.com.senac.sgsst.repository.EpiEntregaRepository;
import br.com.senac.sgsst.repository.EpiRepository;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class DashboardServiceTest {
  final ColaboradorRepository colaboradores = mock(ColaboradorRepository.class);
  final EpiRepository epis = mock(EpiRepository.class);
  final EpiEntregaRepository entregas = mock(EpiEntregaRepository.class);
  final CertificacaoRepository certificacoes = mock(CertificacaoRepository.class);
  final ColaboradorTreinamentoRepository vinculos = mock(ColaboradorTreinamentoRepository.class);
  final ChamadoRepository chamados = mock(ChamadoRepository.class);
  final DashboardService service = new DashboardService(
    colaboradores,
    epis,
    entregas,
    certificacoes,
    vinculos,
    chamados
  );

  final LocalDate hoje = LocalDate.of(2026, 6, 1);
  final LocalDate limite = hoje.plusDays(DashboardService.JANELA_ALERTA_DIAS);
  final LocalDate inicioDasEntregas = hoje.minusDays(DashboardService.JANELA_ALERTA_DIAS);

  /** Zera tudo: cada teste sobrescreve só o que interessa. */
  private void bancoZerado() {
    when(colaboradores.count()).thenReturn(0L);
    when(colaboradores.countByStatus(anyString())).thenReturn(0L);
    when(epis.count()).thenReturn(0L);
    when(epis.somarQuantidades()).thenReturn(0L);
    when(epis.somarQuantidadesComValidadeAnterior(hoje)).thenReturn(0L);
    when(epis.somarQuantidadesComValidadeEntre(hoje, limite)).thenReturn(0L);
    when(entregas.somarQuantidadesNoPeriodo(inicioDasEntregas, hoje)).thenReturn(0L);
    when(certificacoes.countByValidadeLessThan(hoje)).thenReturn(0L);
    when(certificacoes.countByValidadeGreaterThanEqual(hoje)).thenReturn(0L);
    when(certificacoes.countByValidadeBetween(hoje, limite)).thenReturn(0L);
    when(vinculos.count()).thenReturn(0L);
    when(vinculos.countByStatus(anyString())).thenReturn(0L);
    when(vinculos.countByValidadeLessThan(hoje)).thenReturn(0L);
    when(chamados.countByStatus(anyString())).thenReturn(0L);
  }

  @Test void bancoSemDadosDevolveZeroEUmAlertaInformativo() {
    bancoZerado();

    var indicadores = service.indicadores(hoje);

    assertEquals(0, indicadores.colaboradores().total());
    assertEquals(0, indicadores.certificacoes().total());
    assertEquals(0, indicadores.epis().emEstoque());
    assertEquals(0, indicadores.treinamentos().total());
    assertEquals(0, indicadores.treinamentos().porcentagem());
    assertEquals(1, indicadores.alertas().size());
    assertEquals("baixa", indicadores.alertas().get(0).criticidade());
    assertEquals("Geral", indicadores.alertas().get(0).tipo());
    assertNotNull(indicadores.geradoEm());
  }

  @Test void colaboradoresContamPorStatus() {
    bancoZerado();
    when(colaboradores.count()).thenReturn(16L);
    when(colaboradores.countByStatus("Ativo")).thenReturn(12L);
    when(colaboradores.countByStatus("Inativo")).thenReturn(3L);
    when(colaboradores.countByStatus("Afastado")).thenReturn(1L);

    var resumo = service.indicadores(hoje).colaboradores();

    assertEquals(16, resumo.total());
    assertEquals(12, resumo.ativos());
    assertEquals(3, resumo.inativos());
    assertEquals(1, resumo.afastados());
  }

  @Test void certificacoesSepararamAtivasDeVencidas() {
    bancoZerado();
    when(certificacoes.countByValidadeLessThan(hoje)).thenReturn(2L);
    when(certificacoes.countByValidadeGreaterThanEqual(hoje)).thenReturn(5L);
    when(certificacoes.countByValidadeBetween(hoje, limite)).thenReturn(1L);

    var resumo = service.indicadores(hoje).certificacoes();

    assertEquals(7, resumo.total());
    assertEquals(5, resumo.ativas());
    assertEquals(2, resumo.vencidas());
    assertEquals(1, resumo.vencendoEm30Dias());
  }

  @Test void episSomamUnidadesEmEstoqueAVencerEVencidas() {
    bancoZerado();
    when(epis.somarQuantidades()).thenReturn(140L);
    when(epis.somarQuantidadesComValidadeEntre(hoje, limite)).thenReturn(12L);
    when(epis.somarQuantidadesComValidadeAnterior(hoje)).thenReturn(6L);
    when(entregas.somarQuantidadesNoPeriodo(inicioDasEntregas, hoje)).thenReturn(9L);
    when(epis.count()).thenReturn(4L);

    var resumo = service.indicadores(hoje).epis();

    assertEquals(140, resumo.emEstoque());
    assertEquals(12, resumo.proximoVencimento());
    assertEquals(6, resumo.vencidos());
    assertEquals(9, resumo.entreguesUltimos30Dias());
    assertEquals(4, resumo.totalTipos());
  }

  @Test void treinamentosCalculamProgressoEPendentes() {
    bancoZerado();
    when(vinculos.count()).thenReturn(10L);
    when(vinculos.countByStatus("Concluído")).thenReturn(7L);
    when(vinculos.countByValidadeLessThan(hoje)).thenReturn(2L);

    var resumo = service.indicadores(hoje).treinamentos();

    assertEquals(7, resumo.concluidos());
    assertEquals(2, resumo.vencidos());
    // 3 vínculos não concluídos + 2 concluídos com reciclagem vencida.
    assertEquals(5, resumo.pendentes());
    assertEquals(10, resumo.total());
    assertEquals(50, resumo.porcentagem());
  }

  @Test void alertasSaemOrdenadosPorCriticidade() {
    bancoZerado();
    when(epis.somarQuantidades()).thenReturn(140L);
    when(epis.somarQuantidadesComValidadeAnterior(hoje)).thenReturn(6L);
    when(epis.somarQuantidadesComValidadeEntre(hoje, limite)).thenReturn(12L);
    when(certificacoes.countByValidadeLessThan(hoje)).thenReturn(2L);
    when(certificacoes.countByValidadeGreaterThanEqual(hoje)).thenReturn(5L);
    when(chamados.countByStatus("Em andamento")).thenReturn(3L);

    var alertas = service.indicadores(hoje).alertas();

    // As críticas primeiro; dentro do mesmo peso, a ordem em que são geradas.
    assertEquals(4, alertas.size());
    assertEquals(List.of(0, 0, 1, 1), alertas.stream().map(alerta -> peso(alerta.criticidade())).toList());

    assertEquals("EPI", alertas.get(0).tipo());
    assertTrue(alertas.get(0).mensagem().contains("6"));
    assertEquals("Certificação", alertas.get(1).tipo());
    assertTrue(alertas.get(1).mensagem().contains("2"));
    assertEquals("EPI", alertas.get(2).tipo());
    assertTrue(alertas.get(2).mensagem().contains("12"));
    assertEquals("Suporte", alertas.get(3).tipo());
    assertTrue(alertas.get(3).mensagem().contains("3"));
  }

  private int peso(String criticidade) {
    return switch (criticidade) {
      case "alta" -> 0;
      case "media" -> 1;
      default -> 2;
    };
  }

  @Test void consultaAsJanelasDeVencimentoComADataDeReferencia() {
    bancoZerado();

    service.indicadores(hoje);

    verify(epis).somarQuantidadesComValidadeEntre(hoje, limite);
    verify(epis).somarQuantidadesComValidadeAnterior(hoje);
    verify(certificacoes).countByValidadeBetween(hoje, limite);
    verify(vinculos).countByValidadeLessThan(hoje);
    verify(entregas).somarQuantidadesNoPeriodo(hoje.minusDays(30), hoje);
  }
}
