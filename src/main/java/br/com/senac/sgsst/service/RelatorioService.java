package br.com.senac.sgsst.service;

import br.com.senac.sgsst.dto.RelatorioCsv;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.stream.Collectors;

/**
 * Exportação no servidor: monta o CSV a partir dos mesmos serviços que alimentam as telas, para o
 * arquivo baixado refletir o banco e não o que estava carregado no navegador.
 *
 * <p>Formato: separador {@code ;} (padrão que o Excel em português espera), BOM UTF-8 na primeira
 * posição para os acentos saírem certos, cabeçalho na primeira linha e aspas apenas quando o valor
 * contém o separador, aspas ou quebra de linha — assim os números continuam numéricos no Excel.</p>
 */
@Service
@Transactional(readOnly = true)
public class RelatorioService {
  private static final String SEPARADOR = ";";
  private static final String BOM = "\ufeff";
  private static final DateTimeFormatter DATA_HORA =
    DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm").withZone(ZoneId.systemDefault());

  private final DashboardService dashboard;
  private final ColaboradorService colaboradores;
  private final EpiService epis;
  private final CertificacaoService certificacoes;
  private final EpiEntregaService entregas;
  private final ColaboradorTreinamentoService vinculos;

  public RelatorioService(
    DashboardService dashboard,
    ColaboradorService colaboradores,
    EpiService epis,
    CertificacaoService certificacoes,
    EpiEntregaService entregas,
    ColaboradorTreinamentoService vinculos
  ) {
    this.dashboard = dashboard;
    this.colaboradores = colaboradores;
    this.epis = epis;
    this.certificacoes = certificacoes;
    this.entregas = entregas;
    this.vinculos = vinculos;
  }

  /** Indicadores do dashboard na forma Categoria/Métrica/Valor, com os alertas no fim. */
  public RelatorioCsv dashboard() {
    var indicadores = dashboard.indicadores();
    var csv = new StringBuilder(BOM);
    csv.append(linha("Categoria", "Métrica", "Valor"));

    var quadro = indicadores.colaboradores();
    csv.append(linha("Colaboradores", "Total", quadro.total()));
    csv.append(linha("Colaboradores", "Ativos", quadro.ativos()));
    csv.append(linha("Colaboradores", "Inativos", quadro.inativos()));
    csv.append(linha("Colaboradores", "Afastados", quadro.afastados()));

    var certificacoesResumo = indicadores.certificacoes();
    csv.append(linha("Certificações", "Total", certificacoesResumo.total()));
    csv.append(linha("Certificações", "Ativas", certificacoesResumo.ativas()));
    csv.append(linha("Certificações", "Vencidas", certificacoesResumo.vencidas()));
    csv.append(linha("Certificações", "Vencendo em até 30 dias", certificacoesResumo.vencendoEm30Dias()));

    var episResumo = indicadores.epis();
    csv.append(linha("EPIs", "Em estoque (unidades)", episResumo.emEstoque()));
    csv.append(linha("EPIs", "Próximo ao vencimento (unidades)", episResumo.proximoVencimento()));
    csv.append(linha("EPIs", "Vencidos (unidades)", episResumo.vencidos()));
    csv.append(linha("EPIs", "Entregues nos últimos 30 dias (unidades)", episResumo.entreguesUltimos30Dias()));
    csv.append(linha("EPIs", "Tipos cadastrados", episResumo.totalTipos()));

    var treinamentosResumo = indicadores.treinamentos();
    csv.append(linha("Treinamentos", "Total", treinamentosResumo.total()));
    csv.append(linha("Treinamentos", "Concluídos", treinamentosResumo.concluidos()));
    csv.append(linha("Treinamentos", "Pendentes", treinamentosResumo.pendentes()));
    csv.append(linha("Treinamentos", "Vencidos", treinamentosResumo.vencidos()));
    csv.append(linha("Treinamentos", "Progresso (%)", treinamentosResumo.porcentagem()));

    for (var alerta : indicadores.alertas()) {
      csv.append(linha("Alerta", alerta.tipo() + ": " + alerta.mensagem(), alerta.criticidade()));
    }

    return new RelatorioCsv("dashboard-indicadores.csv", csv.toString());
  }

  /**
   * Matriz colaborador × treinamento: uma linha por vínculo registrado. Os vínculos sem validade
   * calculada saem com a coluna de validade vazia.
   */
  public RelatorioCsv matrizTreinamentos() {
    var csv = new StringBuilder(BOM);
    csv.append(linha(
      "Colaborador",
      "Cargo",
      "Treinamento",
      "Situação",
      "Conclusão",
      "Validade"
    ));

    for (var vinculo : vinculos.listar(null)) {
      csv.append(linha(
        vinculo.colaborador(),
        vinculo.cargo(),
        vinculo.treinamento(),
        vinculo.status(),
        vinculo.dataConclusao(),
        vinculo.validade()
      ));
    }

    return new RelatorioCsv("matriz-treinamentos.csv", csv.toString());
  }

  /** Estoque de EPIs com inclusão, validade do CA e saldo atual. */
  public RelatorioCsv epis() {
    var csv = new StringBuilder(BOM);
    csv.append(linha("Descrição", "CA", "Inclusão", "Validade do CA", "Quantidade em estoque"));

    for (var epi : epis.listar()) {
      csv.append(linha(epi.descricao(), epi.ca(), epi.inclusao(), epi.validade(), epi.quantidade()));
    }

    return new RelatorioCsv("epis-estoque.csv", csv.toString());
  }

  /** Entregas de EPI na ordem em que os services devolvem (mais recentes primeiro). */
  public RelatorioCsv entregasEpi() {
    var csv = new StringBuilder(BOM);
    csv.append(linha(
      "Colaborador",
      "Matrícula",
      "EPI",
      "CA no ato",
      "Quantidade",
      "Data da entrega",
      "Assinatura",
      "Registrado em"
    ));

    for (var entrega : entregas.listar(null)) {
      csv.append(linha(
        entrega.colaborador(),
        entrega.matricula(),
        entrega.epi(),
        entrega.ca(),
        entrega.quantidade(),
        entrega.dataEntrega(),
        entrega.assinatura(),
        entrega.registradoEm() == null ? "" : DATA_HORA.format(entrega.registradoEm())
      ));
    }

    return new RelatorioCsv("entregas-epis.csv", csv.toString());
  }

  /** Certificações com a situação calculada na data de hoje (Ativa / Alerta / Vencida). */
  public RelatorioCsv certificacoes() {
    var csv = new StringBuilder(BOM);
    csv.append(linha(
      "Colaborador",
      "Cargo",
      "Treinamento",
      "Instituição",
      "Carga horária",
      "Emitida em",
      "Validade",
      "Situação"
    ));

    for (var certificacao : certificacoes.listar(null)) {
      csv.append(linha(
        certificacao.colaborador(),
        certificacao.cargo(),
        certificacao.treinamento(),
        certificacao.instituicao(),
        certificacao.cargaHoraria(),
        certificacao.emitidaEm(),
        certificacao.validade(),
        certificacao.status()
      ));
    }

    return new RelatorioCsv("certificacoes.csv", csv.toString());
  }

  /** Colaboradores com dados cadastrais e situação. */
  public RelatorioCsv colaboradores() {
    var csv = new StringBuilder(BOM);
    csv.append(linha("Matrícula", "Nome", "CPF", "E-mail", "Cargo", "Setor", "Situação"));

    for (var colaborador : colaboradores.listar()) {
      csv.append(linha(
        colaborador.matricula(),
        colaborador.nome(),
        colaborador.cpf(),
        colaborador.email(),
        colaborador.cargo(),
        colaborador.setor(),
        colaborador.status()
      ));
    }

    return new RelatorioCsv("colaboradores.csv", csv.toString());
  }

  private String linha(Object... campos) {
    return Arrays.stream(campos).map(this::campo).collect(Collectors.joining(SEPARADOR)) + "\n";
  }

  /** Aspas no valor inteiro só quando ele tem separador, aspas ou quebra de linha. */
  private String campo(Object valor) {
    String texto = valor == null ? "" : String.valueOf(valor);

    if (texto.contains(SEPARADOR) || texto.contains("\"") || texto.contains("\n") || texto.contains("\r")) {
      return "\"" + texto.replace("\"", "\"\"") + "\"";
    }

    return texto;
  }
}
