import { Injectable, inject, signal } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { environment } from '../../environments/environment';
import { mensagemErroApi } from './api-error';

export interface LogAuditoria {
  id: number;
  dataHora: string;
  usuario: string;
  modulo: string;
  acao: 'CRIACAO' | 'EDICAO' | 'EXCLUSAO' | 'ACESSO' | 'ALERTA';
  descricao: string;
}

export interface LogAuditoriaFiltros {
  termo?: string;
  /** Datas ISO (yyyy-MM-dd). */
  inicio?: string;
  fim?: string;
}

/** Formato retornado por GET /api/auditoria. */
interface LogAuditoriaApi {
  id: number;
  dataHora: string;
  usuarioId: number | null;
  usuario: string | null;
  modulo: string;
  acao: LogAuditoria['acao'];
  descricao: string;
  metodo: string;
  caminho: string;
  statusHttp: number;
}

@Injectable({
  providedIn: 'root',
})
export class AuditService {
  private readonly http = inject(HttpClient);
  private readonly url = `${environment.apiBaseUrl}/auditoria`;

  readonly logs = signal<LogAuditoria[]>([]);
  readonly erro = signal<string | null>(null);
  readonly carregando = signal<boolean>(false);

  /** Busca os logs persistidos, com filtros opcionais de termo e intervalo de datas. */
  carregar(filtros: LogAuditoriaFiltros = {}): void {
    let params = new HttpParams();
    const termo = filtros.termo?.trim();

    if (termo) {
      params = params.set('termo', termo);
    }

    if (filtros.inicio) {
      params = params.set('inicio', filtros.inicio);
    }

    if (filtros.fim) {
      params = params.set('fim', filtros.fim);
    }

    this.carregando.set(true);

    this.http.get<LogAuditoriaApi[]>(this.url, { params }).subscribe({
      next: (registros) => {
        this.logs.set(registros.map((registro) => this.paraLog(registro)));
        this.erro.set(null);
        this.carregando.set(false);
      },
      error: (erro) => {
        this.erro.set(mensagemErroApi(erro));
        this.carregando.set(false);
      },
    });
  }

  /** Registra um evento manual (POST /api/auditoria). A captura automática é feita no backend. */
  registrarAcao(
    usuario: string,
    modulo: string,
    acao: LogAuditoria['acao'],
    descricao: string,
  ): void {
    this.http
      .post<LogAuditoriaApi>(this.url, { usuario, modulo, acao, descricao })
      .subscribe({
        next: (registro) => this.logs.update((atual) => [this.paraLog(registro), ...atual]),
        error: () => undefined,
      });
  }

  private paraLog(registro: LogAuditoriaApi): LogAuditoria {
    return {
      id: registro.id,
      dataHora: registro.dataHora,
      usuario: registro.usuario ?? 'Sistema',
      modulo: registro.modulo,
      acao: registro.acao,
      descricao: registro.descricao,
    };
  }
}
