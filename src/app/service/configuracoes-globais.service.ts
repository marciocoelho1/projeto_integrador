import { Injectable, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, forkJoin, finalize, map, tap } from 'rxjs';
import { environment } from '../../environments/environment';
import { mensagemErroApi } from './api-error';

/** Regra de alerta como a tela usa (`isAtiva`); a API devolve o campo como `ativa`. */
export interface RegraAlerta {
  codigo: string;
  nomeRegra: string;
  descricaoRegra: string;
  isAtiva: boolean;
}

export interface ParametroSistema {
  chave: string;
  valor: string;
  descricao: string;
}

/** Formato de GET /api/regras-alerta. */
interface RegraAlertaApi {
  codigo: string;
  nomeRegra: string;
  descricaoRegra: string;
  ativa: boolean;
}

@Injectable({
  providedIn: 'root',
})
export class ConfiguracoesGlobaisService {
  private readonly http = inject(HttpClient);
  private readonly regrasUrl = `${environment.apiBaseUrl}/regras-alerta`;
  private readonly parametrosUrl = `${environment.apiBaseUrl}/parametros`;

  readonly regras = signal<RegraAlerta[]>([]);
  readonly parametros = signal<ParametroSistema[]>([]);
  readonly erro = signal<string | null>(null);
  readonly carregando = signal<boolean>(false);
  readonly salvando = signal<boolean>(false);

  /** Carrega as regras de alerta e os parâmetros persistidos (as duas listas de uma vez). */
  carregar(): void {
    this.carregando.set(true);

    forkJoin({
      regras: this.http.get<RegraAlertaApi[]>(this.regrasUrl),
      parametros: this.http.get<ParametroSistema[]>(this.parametrosUrl),
    }).subscribe({
      next: ({ regras, parametros }) => {
        this.regras.set(regras.map((regra) => this.paraRegra(regra)));
        this.parametros.set(parametros);
        this.erro.set(null);
        this.carregando.set(false);
      },
      error: (erro) => {
        this.erro.set(mensagemErroApi(erro));
        this.carregando.set(false);
      },
    });
  }

  /** Grava vários parâmetros de uma vez, mantendo o sinal `salvando` coerente com a requisição. */
  salvarValores(alterados: { chave: string; valor: string }[]): Observable<ParametroSistema[]> {
    this.salvando.set(true);

    return forkJoin(
      alterados.map((parametro) => this.salvarValor(parametro.chave, parametro.valor)),
    ).pipe(finalize(() => this.salvando.set(false)));
  }

  /** PUT /api/regras-alerta/{codigo}: liga ou desliga a regra. */
  definirAtiva(codigo: string, isAtiva: boolean): Observable<RegraAlerta> {
    return this.http.put<RegraAlertaApi>(`${this.regrasUrl}/${codigo}`, { ativa: isAtiva }).pipe(
      map((regra) => this.paraRegra(regra)),
      tap((regra) =>
        this.regras.update((lista) =>
          lista.map((atual) => (atual.codigo === regra.codigo ? regra : atual)),
        ),
      ),
    );
  }

  /** PUT /api/parametros/{chave}: grava o novo valor do parâmetro. */
  salvarValor(chave: string, valor: string): Observable<ParametroSistema> {
    return this.http.put<ParametroSistema>(`${this.parametrosUrl}/${chave}`, { valor }).pipe(
      tap((parametro) =>
        this.parametros.update((lista) =>
          lista.map((atual) => (atual.chave === parametro.chave ? parametro : atual)),
        ),
      ),
    );
  }

  private paraRegra(regra: RegraAlertaApi): RegraAlerta {
    return {
      codigo: regra.codigo,
      nomeRegra: regra.nomeRegra,
      descricaoRegra: regra.descricaoRegra,
      isAtiva: regra.ativa,
    };
  }
}
