import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../environments/environment';

export type TipoImportacao = 'colaborador' | 'treinamento' | 'epi';

/** Erro de uma linha da planilha (linha 1 = cabeçalho). */
export interface ImportacaoErro {
  linha: number;
  mensagem: string;
}

/** Resumo devolvido por POST /api/importacao/<recurso>. */
export interface ImportacaoResultado {
  total: number;
  importados: number;
  ignorados: number;
  erros: ImportacaoErro[];
}

/** Recurso da API de importação para cada tipo de planilha. */
const RECURSO: Record<TipoImportacao, string> = {
  colaborador: 'colaboradores',
  treinamento: 'treinamentos',
  epi: 'epis',
};

@Injectable({ providedIn: 'root' })
export class ImportacaoService {
  private readonly http = inject(HttpClient);
  private readonly url = `${environment.apiBaseUrl}/importacao`;

  importar(tipo: TipoImportacao, linhas: unknown[]) {
    return this.http.post<ImportacaoResultado>(
      `${this.url}/${RECURSO[tipo]}`,
      { linhas },
    );
  }
}
