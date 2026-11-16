import { Injectable, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../environments/environment';
import { mensagemErroApi } from './api-error';

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

@Injectable({
  providedIn: 'root',
})
export class DashboardService {
  private readonly http = inject(HttpClient);
  private readonly url = `${environment.apiBaseUrl}/dashboard/indicadores`;

  readonly indicadores = signal<DashboardIndicadores | null>(null);
  readonly erro = signal<string | null>(null);
  readonly carregando = signal<boolean>(false);

  /** Indicadores calculados no servidor: a tela não tem nenhum número fixo. */
  carregar(): void {
    this.carregando.set(true);

    this.http.get<DashboardIndicadores>(this.url).subscribe({
      next: (indicadores) => {
        this.indicadores.set(indicadores);
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
