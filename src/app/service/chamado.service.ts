import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export type ChamadoTipo = 'Ajuda' | 'Erro';
export type ChamadoStatus = 'Em andamento' | 'Concluída' | 'Cancelada';

export interface Chamado {
  id: number;
  tipo: ChamadoTipo;
  descricao: string;
  usuarioId: number | null;
  solicitante: string;
  status: ChamadoStatus;
  abertoEm: string;
  concluidoEm: string | null;
}

export interface ChamadoRequest {
  tipo: ChamadoTipo;
  descricao: string;
  status?: ChamadoStatus;
  solicitante?: string;
}

export interface ChamadoFiltros {
  status?: string;
  /** true = só os chamados do usuário da sessão (GET /api/chamados?meus=true). */
  meus?: boolean;
}

@Injectable({
  providedIn: 'root',
})
export class ChamadoService {
  private readonly http = inject(HttpClient);
  private readonly url = `${environment.apiBaseUrl}/chamados`;

  listar(filtros: ChamadoFiltros = {}): Observable<Chamado[]> {
    let params = new HttpParams();

    if (filtros.status) {
      params = params.set('status', filtros.status);
    }

    if (filtros.meus) {
      params = params.set('meus', 'true');
    }

    return this.http.get<Chamado[]>(this.url, { params });
  }

  buscarPorId(id: number): Observable<Chamado> {
    return this.http.get<Chamado>(`${this.url}/${id}`);
  }

  criar(dados: ChamadoRequest): Observable<Chamado> {
    return this.http.post<Chamado>(this.url, dados);
  }

  /** Mudança de status: PUT /api/chamados/{id} com o campo status no corpo. */
  atualizarStatus(id: number, dados: ChamadoRequest): Observable<Chamado> {
    return this.http.put<Chamado>(`${this.url}/${id}`, dados);
  }

  excluir(id: number): Observable<void> {
    return this.http.delete<void>(`${this.url}/${id}`);
  }
}
