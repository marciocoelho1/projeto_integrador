import { Component, OnInit, computed, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  DashboardService,
  ResumoCertificacoes,
  ResumoColaboradores,
  ResumoEpis,
  ResumoTreinamentos,
} from '../service/dashboard.service';
import { RelatorioService } from '../service/relatorio.service';
import { ToastService } from '../service/toast.service';

const ZERO_COLABORADORES: ResumoColaboradores = { total: 0, ativos: 0, inativos: 0, afastados: 0 };
const ZERO_CERTIFICACOES: ResumoCertificacoes = { total: 0, ativas: 0, vencidas: 0, vencendoEm30Dias: 0 };
const ZERO_EPIS: ResumoEpis = {
  emEstoque: 0,
  proximoVencimento: 0,
  vencidos: 0,
  entreguesUltimos30Dias: 0,
  totalTipos: 0,
};
const ZERO_TREINAMENTOS: ResumoTreinamentos = {
  concluidos: 0,
  pendentes: 0,
  vencidos: 0,
  total: 0,
  porcentagem: 0,
};

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './dashboard.html',
  styleUrls: ['./dashboard.scss'],
})
export class Dashboard implements OnInit {
  private readonly dashboardService = inject(DashboardService);
  private readonly relatorios = inject(RelatorioService);
  private readonly toast = inject(ToastService);

  protected readonly carregando = this.dashboardService.carregando;
  protected readonly erro = this.dashboardService.erro;

  protected readonly colaboradores = computed(() => this.dashboardService.indicadores()?.colaboradores ?? ZERO_COLABORADORES);
  protected readonly certificacoes = computed(() => this.dashboardService.indicadores()?.certificacoes ?? ZERO_CERTIFICACOES);
  protected readonly epis = computed(() => this.dashboardService.indicadores()?.epis ?? ZERO_EPIS);
  protected readonly treinamentos = computed(() => this.dashboardService.indicadores()?.treinamentos ?? ZERO_TREINAMENTOS);
  protected readonly alertas = computed(() => this.dashboardService.indicadores()?.alertas ?? []);

  protected readonly atualizadoEm = computed(() => {
    const geradoEm = this.dashboardService.indicadores()?.geradoEm;
    return geradoEm ? new Date(geradoEm).toLocaleString('pt-BR') : '';
  });

  /** Unidades com CA válido e fora da janela de alerta (o saldo menos o que vence e o que venceu). */
  protected readonly episComCaValido = computed(() => {
    const resumo = this.epis();
    return Math.max(0, resumo.emEstoque - resumo.proximoVencimento - resumo.vencidos);
  });

  ngOnInit(): void {
    this.dashboardService.carregar();
  }

  protected recarregar(): void {
    this.dashboardService.carregar();
  }

  protected exportarRelatorio(): void {
    this.relatorios.baixar('dashboard', 'relatorio_dashboard.csv').subscribe({
      next: () => this.toast.success('Relatório do dashboard exportado em CSV.'),
      error: () => this.toast.error('Não foi possível gerar o relatório agora.'),
    });
  }

  /** Altura da barra do gráfico: proporção do total, com mínimo para a barra não sumir. */
  protected alturaBarra(valor: number): number {
    const total = this.certificacoes().total;
    return total <= 0 ? 4 : Math.max(4, Math.round((valor * 100) / total));
  }
}
