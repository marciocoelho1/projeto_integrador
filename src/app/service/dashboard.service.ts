import { Injectable, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { forkJoin } from 'rxjs';
import { environment } from '../../environments/environment';
import { mensagemErroApi } from './api-error';
import { ColaboradorService } from './colaborador.service';
import { EpisService } from './epis.service';
import { ChamadoService } from './chamado.service';
import { TreinamentoAvancadoService } from './treinamento-avancado.service';
import { TreinamentoService } from './treinamento.service';
import { AuditService } from './audit.service';
import type { Colaborador } from '../models/colaborador.model';
import type { Treinamento } from '../models/treinamento.model';
import type { VinculoTreinamento } from '../models/treinamento-avancado.model';
import type { Epi, EntregaEpi } from './epis.service';
import type { Chamado } from './chamado.service';
import type { LogAuditoria } from './audit.service';

export interface AlertaIndicador {
  tipo: string;
  mensagem: string;
  criticidade: 'alta' | 'media' | 'baixa';
}

export interface ResumoColaboradores {
  total: number;
  ativos: number;
  inativos: number;
  afastados: number;
}

export interface ResumoCertificacoes {
  total: number;
  ativas: number;
  vencidas: number;
  vencendoEm30Dias: number;
}

export interface ResumoEpis {
  emEstoque: number;
  proximoVencimento: number;
  vencidos: number;
  entreguesUltimos30Dias: number;
  totalTipos: number;
}

export interface ResumoTreinamentos {
  concluidos: number;
  pendentes: number;
  vencidos: number;
  total: number;
  porcentagem: number;
}

/** Formato de GET /api/dashboard/indicadores. */
export interface DashboardIndicadores {
  colaboradores: ResumoColaboradores;
  certificacoes: ResumoCertificacoes;
  epis: ResumoEpis;
  treinamentos: ResumoTreinamentos;
  alertas: AlertaIndicador[];
  geradoEm: string;
}

/**
 * Tudo que o dashboard precisa para montar os dois níveis da tela: os indicadores agregados no
 * servidor (KPIs, alertas, totais) e as listas que o servidor ainda não agrega — setores,
 * vínculos por NR, estoque crítico, entregas, chamados e trilha de auditoria.
 *
 * <p>As listas são pequenas no domínio do SGSST (unidades, não milhares de linhas) e já existem
 * como recursos REST, então a tela as combina no cliente em vez de exigir um endpoint novo.</p>
 */
export interface DadosDashboard {
  indicadores: DashboardIndicadores;
  colaboradores: Colaborador[];
  epis: Epi[];
  entregas: EntregaEpi[];
  chamados: Chamado[];
  vinculos: VinculoTreinamento[];
  treinamentos: Treinamento[];
  logs: LogAuditoria[];
}

@Injectable({
  providedIn: 'root',
})
export class DashboardService {
  private readonly http = inject(HttpClient);
  private readonly url = `${environment.apiBaseUrl}/dashboard/indicadores`;

  private readonly colaboradorService = inject(ColaboradorService);
  private readonly episService = inject(EpisService);
  private readonly chamadoService = inject(ChamadoService);
  private readonly treinamentoAvancado = inject(TreinamentoAvancadoService);
  private readonly treinamentoService = inject(TreinamentoService);
  private readonly auditoria = inject(AuditService);

  readonly dados = signal<DadosDashboard | null>(null);
  readonly erro = signal<string | null>(null);
  readonly carregando = signal<boolean>(false);

  /**
   * Carrega as oito fontes em paralelo. Uma falha em qualquer uma delas deixa a tela inteira em
   * erro em vez de mostrar meia tela com números de momentos diferentes.
   */
  carregar(): void {
    this.carregando.set(true);

    forkJoin({
      indicadores: this.http.get<DashboardIndicadores>(this.url),
      colaboradores: this.colaboradorService.listar(),
      epis: this.episService.obterEpis(),
      entregas: this.episService.obterEntregas(),
      chamados: this.chamadoService.listar(),
      vinculos: this.treinamentoAvancado.listarVinculos(),
      treinamentos: this.treinamentoService.listar(),
      logs: this.auditoria.listar(),
    }).subscribe({
      next: (dados) => {
        this.dados.set(dados);
        this.erro.set(null);
        this.carregando.set(false);
      },
      error: (erro) => {
        this.erro.set(mensagemErroApi(erro));
        this.carregando.set(false);
      },
    });
  }
}
