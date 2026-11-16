import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map, tap } from 'rxjs';
import { environment } from '../../environments/environment';

/** Relatórios em CSV que o servidor gera (ver `RelatorioController`). */
export type RelatorioDisponivel =
  | 'dashboard'
  | 'matriz-treinamentos'
  | 'colaboradores'
  | 'epis'
  | 'certificacoes'
  | 'entregas-epis';

@Injectable({
  providedIn: 'root',
})
export class RelatorioService {
  private readonly http = inject(HttpClient);
  private readonly url = `${environment.apiBaseUrl}/relatorios`;

  /**
   * Baixa o CSV gerado no servidor. O arquivo reflete o banco, e não o que a tela já carregou —
   * a matriz, por exemplo, sai completa mesmo sem a Visão Geral aberta.
   */
  baixar(relatorio: RelatorioDisponivel, nomeArquivo = `${relatorio}.csv`): Observable<void> {
    return this.http.get(`${this.url}/${relatorio}.csv`, { responseType: 'blob' }).pipe(
      tap((arquivo) => this.salvar(arquivo, nomeArquivo)),
      map(() => undefined),
    );
  }

  private salvar(arquivo: Blob, nomeArquivo: string): void {
    const url = URL.createObjectURL(arquivo);
    const link = document.createElement('a');

    link.href = url;
    link.download = nomeArquivo;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  }
}
