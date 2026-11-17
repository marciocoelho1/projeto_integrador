import { Injectable, inject, signal } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, map } from 'rxjs';
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

  /**
   * Busca os logs persistidos, com filtros opcionais de termo e intervalo de datas.
   * Grava o resultado no estado compartilhado da tela de logs.
   */
  carregar(filtros: LogAuditoriaFiltros = {}): void {
    this.carregando.set(true);

    this.listar(filtros).subscribe({
      next: (registros) => {
        this.logs.set(registros);
        this.erro.set(null);
        this.carregando.set(false);
      },
      error: (erro) => {
        this.erro.set(mensagemErroApi(erro));
        this.carregando.set(false);
      },
    });
  }

  /**
   * Mesma consulta do {@link carregar}, mas devolvida como Observable e sem tocar no estado
   * compartilhado: quem só precisa ler os últimos eventos (o dashboard) não mexe na tela de logs.
   */
  listar(filtros: LogAuditoriaFiltros = {}): Observable<LogAuditoria[]> {
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

    return this.http
      .get<LogAuditoriaApi[]>(this.url, { params })
      .pipe(map((registros) => registros.map((registro) => this.paraLog(registro))));
  }

  /** Registra um evento manual (POST /api/auditoria). A captura automática é feita no backend. */
  registrarAcao(
    usuario: string,
    modulo: string,
    acao: LogAuditoria['acao'],
    descricao: string,
  ): void {
    this.http.post<LogAuditoriaApi>(this.url, { usuario, modulo, acao, descricao }).subscribe({
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
