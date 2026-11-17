import { Component, OnInit, computed, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { DashboardService } from '../service/dashboard.service';
import { RelatorioService } from '../service/relatorio.service';
import { ToastService } from '../service/toast.service';
import type { VinculoTreinamento } from '../models/treinamento-avancado.model';

/** Estoque igual ou abaixo disso entra no card "EPIs em estoque crítico". */
const ESTOQUE_MINIMO = 5;

/** Janela de "a vencer", a mesma que o backend usa no DashboardService. */
const JANELA_ALERTA_DIAS = 30;

/** Quantos itens cabem nas listas curtas do painel. */
const LIMITE_LISTA = 5;

/** A barra mais alta do gráfico de entregas fica em 88% para caber o rótulo do mês. */
const ALTURA_MAXIMA_BARRA = 88;

const MESES_CURTOS = [
  'Jan',
  'Fev',
  'Mar',
  'Abr',
  'Mai',
  'Jun',
  'Jul',
  'Ago',
  'Set',
  'Out',
  'Nov',
  'Dez',
];

interface KpiView {
  chave: string;
  rotulo: string;
  valor: number;
  sufixo: string;
  dica: { valor: string; texto: string }[];
  cor: 'blue' | 'red' | 'amber' | 'slate';
}

interface PendenciaView {
  id: string;
  criticidade: 'alta' | 'media' | 'baixa';
  rotulo: string;
  chip: 'red' | 'amber' | 'green';
  tipo: string;
  mensagem: string;
  acao: string | null;
  rota: string | null;
}

interface NrConformidadeView {
  nr: string;
  emDia: number;
  vencidos: number;
  porcentagem: number;
}

interface ConformidadeView {
  porcentagem: number;
  total: number;
  emDia: number;
  aVencer: number;
  vencidos: number;
  pendentes: number;
  /** Fatias da barra empilhada, já em porcentagem do total. */
  fatiaAVencer: number;
  fatiaVencidos: number;
  fatiaPendentes: number;
  porNr: NrConformidadeView[];
}

interface HeatCelula {
  nr: string;
  valor: number;
  nivel: number;
}

interface HeatLinha {
  setor: string;
  celulas: HeatCelula[];
  total: number;
}

interface HeatView {
  nrs: string[];
  linhas: HeatLinha[];
  totaisPorNr: number[];
  total: number;
}

interface SetorBarra {
  setor: string;
  total: number;
  largura: number;
}

interface EpiCriticoView {
  id: number;
  descricao: string;
  ca: string;
  quantidade: number;
  situacao: string;
  chip: 'red' | 'amber' | 'slate';
}

interface MesBarra {
  rotulo: string;
  valor: number;
  altura: number;
}

interface EntregaView {
  id: number;
  colaborador: string;
  epi: string;
  quantidade: number;
  data: string;
  assinado: boolean;
}

interface AtividadeView {
  id: number;
  descricao: string;
  quando: string;
  cor: string;
}

function doisDigitos(valor: number): string {
  return String(valor).padStart(2, '0');
}

/** Data local no formato ISO curto (yyyy-MM-dd): nesse formato a comparação como texto é segura. */
function emIso(data: Date): string {
  return `${data.getFullYear()}-${doisDigitos(data.getMonth() + 1)}-${doisDigitos(data.getDate())}`;
}

function hojeIso(): string {
  return emIso(new Date());
}

function somarDias(iso: string, dias: number): string {
  const data = new Date(`${iso}T00:00:00`);
  data.setDate(data.getDate() + dias);

  return emIso(data);
}

/** Data (LocalDate da API) sem passar por Date: evita o fuso deslocar o dia. */
function formatarData(iso: string | null | undefined): string {
  const partes = (iso ?? '').slice(0, 10).split('-');

  return partes.length === 3 ? `${partes[2]}/${partes[1]}/${partes[0]}` : '';
}

function formatarDataHora(iso: string | null | undefined): string {
  if (!iso) return '';

  const data = new Date(iso);
  if (Number.isNaN(data.getTime())) return '';

  return `${doisDigitos(data.getDate())}/${doisDigitos(data.getMonth() + 1)} · ${doisDigitos(data.getHours())}:${doisDigitos(data.getMinutes())}`;
}

function formatarDataHoraCompleta(iso: string | null | undefined): string {
  if (!iso) return '';

  const data = new Date(iso);
  if (Number.isNaN(data.getTime())) return '';

  return `${formatarData(iso)} ${doisDigitos(data.getHours())}:${doisDigitos(data.getMinutes())}`;
}

function pluralizar(valor: number, singular: string, plural: string): string {
  return `${valor} ${valor === 1 ? singular : plural}`;
}

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './dashboard.html',
  styleUrls: ['./dashboard.scss'],
})
export class Dashboard implements OnInit {
  private readonly dashboardService = inject(DashboardService);
  private readonly relatorios = inject(RelatorioService);
  private readonly toast = inject(ToastService);

  protected readonly carregando = this.dashboardService.carregando;
  protected readonly erro = this.dashboardService.erro;

  /** Janela de "a vencer" exibida nos subtítulos dos cards. */
  protected readonly janelaAlertaDias = JANELA_ALERTA_DIAS;

  /** Tudo que o painel usa: indicadores do servidor + as listas que ele agrega no cliente. */
  protected readonly dados = computed(() => this.dashboardService.dados());

  protected readonly atualizadoEm = computed(() =>
    formatarDataHoraCompleta(this.dashboardService.dados()?.indicadores.geradoEm),
  );

  ngOnInit(): void {
    this.dashboardService.carregar();
  }

  /* =======================================================
     Indicadores principais (KPIs)
     ======================================================= */

  protected readonly kpis = computed<KpiView[]>(() => {
    const indicadores = this.dados()?.indicadores;
    if (!indicadores) return [];

    const { colaboradores, certificacoes, epis } = indicadores;
    const chamados = this.dados()?.chamados ?? [];
    const abertos = chamados.filter((chamado) => chamado.status === 'Em andamento').length;
    const concluidosNoMes = chamados.filter(
      (chamado) => chamado.status === 'Concluída' && this.noMesAtual(chamado.concluidoEm),
    ).length;
    const criticos = this.episCriticos();
    const tiposCriticos = criticos.itens.length + criticos.restantes;

    return [
      {
        chave: 'colaboradores',
        rotulo: 'Colaboradores ativos',
        valor: colaboradores.ativos,
        sufixo: `/ ${colaboradores.total}`,
        dica: [
          {
            valor: String(colaboradores.afastados),
            texto: colaboradores.afastados === 1 ? 'afastado' : 'afastados',
          },
          {
            valor: String(colaboradores.inativos),
            texto: colaboradores.inativos === 1 ? 'inativo' : 'inativos',
          },
        ],
        cor: 'blue',
      },
      {
        chave: 'epis',
        rotulo: 'EPIs em estoque',
        valor: epis.emEstoque,
        sufixo: 'un.',
        dica: [
          {
            valor: String(tiposCriticos),
            texto: tiposCriticos === 1 ? 'tipo em nível crítico' : 'tipos em nível crítico',
          },
          {
            valor: String(epis.vencidos),
            texto: epis.vencidos === 1 ? 'unidade vencida' : 'unidades vencidas',
          },
        ],
        cor: 'red',
      },
      {
        chave: 'certificacoes',
        rotulo: 'Certificações',
        valor: certificacoes.ativas,
        sufixo: 'ativas',
        dica: [
          {
            valor: String(certificacoes.vencidas),
            texto: certificacoes.vencidas === 1 ? 'vencida' : 'vencidas',
          },
          {
            valor: String(certificacoes.vencendoEm30Dias),
            texto: certificacoes.vencendoEm30Dias === 1 ? 'a vencer' : 'a vencer',
          },
        ],
        cor: 'amber',
      },
      {
        chave: 'chamados',
        rotulo: 'Chamados de suporte',
        valor: abertos,
        sufixo: abertos === 1 ? 'aberto' : 'abertos',
        dica: [{ valor: String(concluidosNoMes), texto: 'concluído(s) no mês' }],
        cor: 'slate',
      },
    ];
  });

  /* =======================================================
     Card "Precisa de atenção"
     ======================================================= */

  /** Pendências abertas = alertas que o servidor derivou dos indicadores. */
  protected readonly pendencias = computed<PendenciaView[]>(() =>
    (this.dados()?.indicadores.alertas ?? []).map((alerta) => {
      const acao = this.acaoDoAlerta(alerta.tipo);

      return {
        id: `${alerta.tipo}-${alerta.mensagem}`,
        criticidade: alerta.criticidade,
        rotulo:
          alerta.criticidade === 'alta'
            ? 'Alta'
            : alerta.criticidade === 'media'
              ? 'Média'
              : 'Baixa',
        chip:
          alerta.criticidade === 'alta'
            ? 'red'
            : alerta.criticidade === 'media'
              ? 'amber'
              : 'green',
        tipo: alerta.tipo,
        mensagem: alerta.mensagem,
        acao: acao?.rotulo ?? null,
        rota: acao?.rota ?? null,
      };
    }),
  );

  /** Só alta e média exigem decisão; a "baixa" é o informativo de que não há pendência. */
  protected readonly totalPendencias = computed(
    () => this.pendencias().filter((pendencia) => pendencia.criticidade !== 'baixa').length,
  );

  /** Linha do cabeçalho: quantos ativos, quantos afastados e a idade do cálculo. */
  protected readonly resumo = computed(() => {
    const colaboradores = this.dados()?.indicadores.colaboradores;
    if (!colaboradores) return '';

    const partes = [
      `${colaboradores.ativos} de ${colaboradores.total} colaborador(es) ativo(s)`,
      pluralizar(colaboradores.afastados, 'afastado', 'afastados'),
    ];
    const atualizado = formatarDataHoraCompleta(this.dados()?.indicadores.geradoEm);

    if (atualizado) partes.push(`atualizado em ${atualizado}`);

    return partes.join(' · ');
  });

  /* =======================================================
     Conformidade de treinamentos
     ======================================================= */

  protected readonly conformidade = computed<ConformidadeView>(() => {
    const hoje = hojeIso();
    const limite = somarDias(hoje, JANELA_ALERTA_DIAS);

    // A contagem sai da lista de vínculos (GET /api/vinculos) para os quatro baldes fecharem
    // exatamente o total do card. O indicador do servidor (`treinamentos.porcentagem`) conta o
    // que vence em 30 dias como "em dia" e não separa os vínculos ainda pendentes.
    const baldes = { emDia: 0, aVencer: 0, vencidos: 0, pendentes: 0 };

    for (const vinculo of this.dados()?.vinculos ?? []) {
      baldes[this.baldeDoVinculo(vinculo, hoje, limite)] += 1;
    }

    const total = baldes.emDia + baldes.aVencer + baldes.vencidos + baldes.pendentes;

    return {
      porcentagem: this.percentual(baldes.emDia, total),
      total: total,
      emDia: baldes.emDia,
      aVencer: baldes.aVencer,
      vencidos: baldes.vencidos,
      pendentes: baldes.pendentes,
      fatiaAVencer: this.percentual(baldes.aVencer, total),
      fatiaVencidos: this.percentual(baldes.vencidos, total),
      fatiaPendentes: this.percentual(baldes.pendentes, total),
      porNr: this.conformidadePorNr(hoje, limite),
    };
  });

  /**
   * Balde de um vínculo na barra de conformidade: "em dia" é o concluído e fora da janela de
   * alerta; o que já venceu conta como vencido e o que ainda não foi concluído é pendente.
   */
  private baldeDoVinculo(
    vinculo: VinculoTreinamento,
    hoje: string,
    limite: string,
  ): 'emDia' | 'aVencer' | 'vencidos' | 'pendentes' {
    if (vinculo.validade && vinculo.validade < hoje) return 'vencidos';
    if (vinculo.status !== 'Concluído') return 'pendentes';
    if (vinculo.validade && vinculo.validade <= limite) return 'aVencer';

    return 'emDia';
  }

  private conformidadePorNr(hoje: string, limite: string): NrConformidadeView[] {
    const nrPorTreinamento = new Map(
      (this.dados()?.treinamentos ?? []).map((treinamento) => [treinamento.id, treinamento.nr]),
    );
    const grupos = new Map<string, { emDia: number; vencidos: number; total: number }>();

    for (const vinculo of this.dados()?.vinculos ?? []) {
      const nr =
        vinculo.treinamentoId == null
          ? null
          : (nrPorTreinamento.get(vinculo.treinamentoId) ?? null);
      if (!nr) continue;

      const grupo = grupos.get(nr) ?? { emDia: 0, vencidos: 0, total: 0 };
      const balde = this.baldeDoVinculo(vinculo, hoje, limite);

      grupo.total += 1;
      if (balde === 'emDia') grupo.emDia += 1;
      if (balde === 'vencidos') grupo.vencidos += 1;

      grupos.set(nr, grupo);
    }

    return [...grupos.entries()]
      .map(([nr, grupo]) => ({
        nr,
        emDia: grupo.emDia,
        vencidos: grupo.vencidos,
        porcentagem: this.percentual(grupo.emDia, grupo.total),
      }))
      .sort((a, b) => a.nr.localeCompare(b.nr, 'pt-BR', { numeric: true }));
  }

  /* =======================================================
     Pendências por NR e setor
     ======================================================= */

  protected readonly heat = computed<HeatView>(() => {
    const dados = this.dados();
    const hoje = hojeIso();
    const limite = somarDias(hoje, JANELA_ALERTA_DIAS);

    const setorPorColaborador = new Map(
      (dados?.colaboradores ?? []).map((c) => [c.id, c.setor || 'Sem setor']),
    );
    const nrPorTreinamento = new Map(
      (dados?.treinamentos ?? []).map((treinamento) => [treinamento.id, treinamento.nr]),
    );

    const contagem = new Map<string, number>();
    const nrs = new Set<string>();

    for (const vinculo of dados?.vinculos ?? []) {
      const nr =
        vinculo.treinamentoId == null
          ? null
          : (nrPorTreinamento.get(vinculo.treinamentoId) ?? null);
      // Sem NR não há coluna na matriz: esses vínculos ficam só na conformidade geral.
      if (!nr) continue;
      // Pendência = validade vencida ou vencendo dentro da janela de alerta.
      if (!vinculo.validade || vinculo.validade > limite) continue;

      const setor = setorPorColaborador.get(vinculo.colaboradorId) ?? 'Sem setor';
      const chave = `${setor}|${nr}`;

      nrs.add(nr);
      contagem.set(chave, (contagem.get(chave) ?? 0) + 1);
    }

    const colunas = [...nrs].sort((a, b) => a.localeCompare(b, 'pt-BR', { numeric: true }));
    const setores = [...new Set((dados?.colaboradores ?? []).map((c) => c.setor || 'Sem setor'))];

    const linhas: HeatLinha[] = setores
      .map((setor) => {
        const celulas = colunas.map((nr) => {
          const valor = contagem.get(`${setor}|${nr}`) ?? 0;

          return { nr, valor, nivel: valor === 0 ? 0 : valor === 1 ? 1 : 2 };
        });

        return { setor, celulas, total: celulas.reduce((soma, celula) => soma + celula.valor, 0) };
      })
      .sort((a, b) => b.total - a.total || a.setor.localeCompare(b.setor, 'pt-BR'));

    const totaisPorNr = colunas.map((_, indice) =>
      linhas.reduce((soma, linha) => soma + linha.celulas[indice].valor, 0),
    );

    return {
      nrs: colunas,
      linhas,
      totaisPorNr,
      total: totaisPorNr.reduce((soma, valor) => soma + valor, 0),
    };
  });

  /* =======================================================
     Colaboradores por setor
     ======================================================= */

  protected readonly porSetor = computed<SetorBarra[]>(() => {
    const contagem = new Map<string, number>();

    for (const colaborador of this.dados()?.colaboradores ?? []) {
      const setor = colaborador.setor || 'Sem setor';
      contagem.set(setor, (contagem.get(setor) ?? 0) + 1);
    }

    const linhas = [...contagem.entries()].map(([setor, total]) => ({ setor, total }));
    linhas.sort((a, b) => b.total - a.total || a.setor.localeCompare(b.setor, 'pt-BR'));

    const maior = linhas.reduce((maximo, linha) => Math.max(maximo, linha.total), 0);

    return linhas.map((linha) => ({
      ...linha,
      largura: maior > 0 ? Math.round((linha.total * 100) / maior) : 0,
    }));
  });

  /** Descrição textual das barras para leitores de tela (o gráfico é uma imagem para o ARIA). */
  protected readonly rotuloSetores = computed(() =>
    this.porSetor()
      .map((linha) => `${linha.setor} ${linha.total}`)
      .join(', '),
  );

  /* =======================================================
     EPIs em estoque crítico
     ======================================================= */

  /** Limite mostrado no subtítulo do card; o corte é o mesmo usado no filtro acima. */
  protected readonly estoqueMinimo = ESTOQUE_MINIMO;

  protected readonly episCriticos = computed<{ itens: EpiCriticoView[]; restantes: number }>(() => {
    const hoje = hojeIso();

    const criticos = (this.dados()?.epis ?? [])
      .filter((epi) => epi.quantidade <= ESTOQUE_MINIMO)
      .map<EpiCriticoView>((epi) => {
        const vencido = !!epi.validade && epi.validade < hoje;
        const situacao = vencido
          ? 'Vencido'
          : epi.quantidade <= 3
            ? 'Crítico'
            : epi.quantidade === 4
              ? 'Atenção'
              : 'No mínimo';

        return {
          id: epi.id,
          descricao: epi.descricao,
          ca: epi.ca,
          quantidade: epi.quantidade,
          situacao,
          chip:
            situacao === 'Vencido' || situacao === 'Crítico'
              ? 'red'
              : situacao === 'Atenção'
                ? 'amber'
                : 'slate',
        };
      })
      .sort(
        (a, b) => a.quantidade - b.quantidade || a.descricao.localeCompare(b.descricao, 'pt-BR'),
      );

    return {
      itens: criticos.slice(0, LIMITE_LISTA),
      restantes: Math.max(0, criticos.length - LIMITE_LISTA),
    };
  });

  /* =======================================================
     Entregas de EPI (6 meses) e últimas entregas
     ======================================================= */

  protected readonly entregasPorMes = computed<{ total: number; meses: MesBarra[] }>(() => {
    const hoje = new Date();
    const meses = Array.from({ length: 6 }, (_, indice) => {
      const referencia = new Date(hoje.getFullYear(), hoje.getMonth() - (5 - indice), 1);

      return {
        chave: `${referencia.getFullYear()}-${doisDigitos(referencia.getMonth() + 1)}`,
        rotulo: MESES_CURTOS[referencia.getMonth()],
        valor: 0,
      };
    });

    const indicePorChave = new Map(meses.map((mes, indice) => [mes.chave, indice]));

    for (const entrega of this.dados()?.entregas ?? []) {
      const indice = indicePorChave.get((entrega.dataEntrega ?? '').slice(0, 7));
      if (indice === undefined) continue;

      meses[indice].valor += entrega.quantidade;
    }

    const maior = meses.reduce((maximo, mes) => Math.max(maximo, mes.valor), 0);

    return {
      total: meses.reduce((soma, mes) => soma + mes.valor, 0),
      meses: meses.map((mes) => ({
        rotulo: mes.rotulo,
        valor: mes.valor,
        altura: maior > 0 ? Math.max(4, Math.round((mes.valor * ALTURA_MAXIMA_BARRA) / maior)) : 4,
      })),
    };
  });

  /** Descrição textual das barras do gráfico de entregas, para o aria-label. */
  protected readonly rotuloEntregas = computed(() =>
    this.entregasPorMes()
      .meses.map((mes) => `${mes.rotulo}: ${mes.valor}`)
      .join(', '),
  );

  protected readonly ultimasEntregas = computed<EntregaView[]>(() =>
    [...(this.dados()?.entregas ?? [])]
      .sort(
        (a, b) =>
          (b.dataEntrega ?? '').localeCompare(a.dataEntrega ?? '') ||
          (b.registradoEm ?? '').localeCompare(a.registradoEm ?? ''),
      )
      .slice(0, LIMITE_LISTA)
      .map((entrega) => ({
        id: entrega.id,
        colaborador: entrega.colaborador,
        epi: entrega.epi,
        quantidade: entrega.quantidade,
        data: formatarData(entrega.dataEntrega),
        assinado: !!entrega.assinatura,
      })),
  );

  /* =======================================================
     Atividade recente (trilha de auditoria)
     ======================================================= */

  protected readonly atividade = computed<AtividadeView[]>(() =>
    [...(this.dados()?.logs ?? [])]
      .sort((a, b) => (b.dataHora ?? '').localeCompare(a.dataHora ?? ''))
      .slice(0, LIMITE_LISTA)
      .map((log) => ({
        id: log.id,
        descricao: log.descricao,
        quando: formatarDataHora(log.dataHora),
        cor: this.corDoLog(log.acao),
      })),
  );

  /* =======================================================
     Ações da tela
     ======================================================= */

  protected recarregar(): void {
    this.dashboardService.carregar();
  }

  protected exportarRelatorio(): void {
    this.relatorios.baixar('dashboard', 'relatorio_dashboard.csv').subscribe({
      next: () => this.toast.success('Relatório do dashboard exportado em CSV.'),
      error: () => this.toast.error('Não foi possível gerar o relatório agora.'),
    });
  }

  private percentual(parte: number, total: number): number {
    return total <= 0 ? 0 : Math.round((parte * 100) / total);
  }

  private noMesAtual(iso: string | null | undefined): boolean {
    if (!iso) return false;

    const data = new Date(iso);
    if (Number.isNaN(data.getTime())) return false;

    const agora = new Date();

    return data.getFullYear() === agora.getFullYear() && data.getMonth() === agora.getMonth();
  }

  /** Cada tipo de alerta aponta para a tela onde a pendência é resolvida. */
  private acaoDoAlerta(tipo: string): { rotulo: string; rota: string } | null {
    if (tipo === 'EPI') return { rotulo: 'Repor', rota: '/epis' };
    if (tipo === 'Treinamento') return { rotulo: 'Agendar', rota: '/matriz-treinamentos' };
    if (tipo === 'Certificação')
      return { rotulo: 'Ver certificações', rota: '/matriz-treinamentos' };
    if (tipo === 'Suporte') return { rotulo: 'Responder', rota: '/ajuda-suporte' };

    return null;
  }

  private corDoLog(acao: string): string {
    if (acao === 'CRIACAO') return 'feed__dot--blue';
    if (acao === 'EDICAO') return 'feed__dot--green';
    if (acao === 'EXCLUSAO') return 'feed__dot--red';
    if (acao === 'ALERTA') return 'feed__dot--amber';

    return '';
  }
}
