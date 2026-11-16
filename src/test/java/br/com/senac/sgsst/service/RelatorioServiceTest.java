package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.AlertaIndicador;
import br.com.senac.sgsst.dto.CertificacaoResponse;
import br.com.senac.sgsst.dto.ColaboradorResponse;
import br.com.senac.sgsst.dto.ColaboradorTreinamentoResponse;
import br.com.senac.sgsst.dto.DashboardIndicadoresResponse;
import br.com.senac.sgsst.dto.EpiEntregaResponse;
import br.com.senac.sgsst.dto.EpiResponse;
import br.com.senac.sgsst.dto.ResumoCertificacoes;
import br.com.senac.sgsst.dto.ResumoColaboradores;
import br.com.senac.sgsst.dto.ResumoEpis;
import br.com.senac.sgsst.dto.ResumoTreinamentos;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class RelatorioServiceTest {
  final DashboardService dashboard = mock(DashboardService.class);
  final ColaboradorService colaboradores = mock(ColaboradorService.class);
  final EpiService epis = mock(EpiService.class);
  final CertificacaoService certificacoes = mock(CertificacaoService.class);
  final EpiEntregaService entregas = mock(EpiEntregaService.class);
  final ColaboradorTreinamentoService vinculos = mock(ColaboradorTreinamentoService.class);
  final RelatorioService service = new RelatorioService(
    dashboard,
    colaboradores,
    epis,
    certificacoes,
    entregas,
    vinculos
  );

  private void dashboardPreenchido() {
    when(dashboard.indicadores()).thenReturn(new DashboardIndicadoresResponse(
      new ResumoColaboradores(16, 12, 3, 1),
      new ResumoCertificacoes(7, 5, 2, 1),
      new ResumoEpis(140, 12, 6, 9, 4),
      new ResumoTreinamentos(7, 5, 2, 10, 50),
      List.of(new AlertaIndicador("EPI", "6 unidade(s) de EPI com CA vencido no estoque.", "alta")),
      OffsetDateTime.parse("2026-06-01T10:00:00-03:00")
    ));
  }

  @Test void dashboardSaiComoCategoriaMetricaValor() {
    dashboardPreenchido();

    var relatorio = service.dashboard();

    assertEquals("dashboard-indicadores.csv", relatorio.nomeArquivo());
    assertTrue(relatorio.conteudo().startsWith("\ufeff"), "o CSV precisa começar com o BOM UTF-8");
    assertTrue(relatorio.conteudo().contains("Categoria;Métrica;Valor\n"));
    assertTrue(relatorio.conteudo().contains("Colaboradores;Total;16\n"));
    assertTrue(relatorio.conteudo().contains("Certificações;Vencendo em até 30 dias;1\n"));
    assertTrue(relatorio.conteudo().contains("EPIs;Em estoque (unidades);140\n"));
    assertTrue(relatorio.conteudo().contains("EPIs;Entregues nos últimos 30 dias (unidades);9\n"));
    assertTrue(relatorio.conteudo().contains("Treinamentos;Progresso (%);50\n"));
    assertTrue(relatorio.conteudo().contains("Alerta;EPI: 6 unidade(s) de EPI com CA vencido no estoque.;alta\n"));
  }

  @Test void matrizTemUmaLinhaPorVinculoComValidadeVaziaQuandoNaoCalculada() {
    when(vinculos.listar(null)).thenReturn(List.of(
      new ColaboradorTreinamentoResponse(1, 1, "Carlos Eduardo Silva", "Operador de Empilhadeira", 2,
        "NR-11 Operação Segura de Empilhadeira", LocalDate.of(2026, 1, 10), "Concluído", LocalDate.of(2027, 1, 10)),
      new ColaboradorTreinamentoResponse(2, 2, "Ana Ribeiro", "Auxiliar de Loja", 3,
        "NR-35 Trabalho em Altura", null, "Pendente", null)
    ));

    var relatorio = service.matrizTreinamentos();

    assertEquals("matriz-treinamentos.csv", relatorio.nomeArquivo());
    var linhas = relatorio.conteudo().split("\n");
    assertEquals(3, linhas.length);
    assertEquals("Colaborador;Cargo;Treinamento;Situação;Conclusão;Validade", linhas[0].replace("\ufeff", ""));
    assertEquals(
      "Carlos Eduardo Silva;Operador de Empilhadeira;NR-11 Operação Segura de Empilhadeira;Concluído;2026-01-10;2027-01-10",
      linhas[1]
    );
    assertEquals("Ana Ribeiro;Auxiliar de Loja;NR-35 Trabalho em Altura;Pendente;;", linhas[2]);
  }

  @Test void valorComSeparadorOuAspasRecebeAspasDuplicadas() {
    when(epis.listar()).thenReturn(List.of(
      new EpiResponse(1, "Luva; Nitrílica \"Pro\"", "123", LocalDate.of(2026, 1, 1), LocalDate.of(2027, 1, 1), 40)
    ));

    var conteudo = service.epis().conteudo();

    assertTrue(conteudo.contains("\"Luva; Nitrílica \"\"Pro\"\"\";123;2026-01-01;2027-01-01;40\n"));
  }

  @Test void entregaTrazDataHoraFormatadaENaoInstanteIso() {
    when(entregas.listar(null)).thenReturn(List.of(
      new EpiEntregaResponse(1, 1, "Ana Ribeiro", "M01", 7, "Capacete", "123", 2,
        LocalDate.of(2026, 6, 1), "Ana Ribeiro", Instant.parse("2026-06-01T13:30:00Z"))
    ));

    var linha = service.entregasEpi().conteudo().split("\n")[1];

    assertEquals(8, linha.split(";").length);
    assertTrue(linha.startsWith("Ana Ribeiro;M01;Capacete;123;2;2026-06-01;Ana Ribeiro;"));
    assertFalse(linha.contains("2026-06-01T13:30:00Z"));
  }

  @Test void certificacoesEColaboradoresSaemComSituacao() {
    when(certificacoes.listar(null)).thenReturn(List.of(
      new CertificacaoResponse(1, 1, "Carlos Eduardo Silva", "Operador", 2, "NR-11", "SENAC",
        "8 horas", LocalDate.of(2025, 1, 10), LocalDate.of(2026, 1, 10), null, "Vencida")
    ));
    when(colaboradores.listar()).thenReturn(List.of(
      new ColaboradorResponse(1, "M01", "Carlos Eduardo Silva", "12345678901", "carlos@example.test",
        "Operador", "Estoque / Logística", "Ativo")
    ));

    var certificacoesCsv = service.certificacoes().conteudo();
    assertEquals("certificacoes.csv", service.certificacoes().nomeArquivo());
    assertTrue(certificacoesCsv.contains(
      "Colaborador;Cargo;Treinamento;Instituição;Carga horária;Emitida em;Validade;Situação\n"
    ));
    assertTrue(certificacoesCsv.contains(
      "Carlos Eduardo Silva;Operador;NR-11;SENAC;8 horas;2025-01-10;2026-01-10;Vencida\n"
    ));

    var colaboradoresCsv = service.colaboradores().conteudo();
    assertTrue(colaboradoresCsv.contains("Matrícula;Nome;CPF;E-mail;Cargo;Setor;Situação\n"));
    assertTrue(colaboradoresCsv.contains(
      "M01;Carlos Eduardo Silva;12345678901;carlos@example.test;Operador;Estoque / Logística;Ativo\n"
    ));
  }
}
