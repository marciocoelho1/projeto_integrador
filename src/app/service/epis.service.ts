import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface Epi {
  id: number;
  descricao: string;
  quantidade: number;
  inclusao: string;
  validade: string;
  ca: string;
}

export type EpiRequest = Omit<Epi, 'id'>;

/** Entrega de EPI como a API devolve, com os campos de exibição já resolvidos. */
export interface EntregaEpi {
  id: number;
  colaboradorId: number;
  colaborador: string;
  matricula: string;
  epiId: number;
  epi: string;
  ca: string;
  quantidade: number;
  dataEntrega: string;
  assinatura: string;
  registradoEm?: string;
}

/** Corpo do POST /api/entregas-epis: o que a tela precisa informar para registrar a entrega. */
export interface EntregaEpiRequest {
  colaboradorId: number;
  epiId: number;
  quantidade: number;
  dataEntrega: string;
  assinatura: string;
}

@Injectable({
  providedIn: 'root',
})
export class EpisService {
  private apiUrl = `${environment.apiBaseUrl}/epis`;
  private apiEntregasUrl = `${environment.apiBaseUrl}/entregas-epis`;

  constructor(private http: HttpClient) {}

  /* =======================================================
     MÉTODOS - GESTÃO DE ESTOQUE / CADASTRO DE EPIs
     ======================================================= */

  obterEpis(): Observable<Epi[]> {
    return this.http.get<Epi[]>(this.apiUrl);
  }

  obterEpiPorId(id: number): Observable<Epi> {
    return this.http.get<Epi>(`${this.apiUrl}/${id}`);
  }

  cadastrarEpi(epi: EpiRequest): Observable<Epi> {
    return this.http.post<Epi>(this.apiUrl, epi);
  }

  atualizarEpi(id: number, epi: EpiRequest): Observable<Epi> {
    return this.http.put<Epi>(`${this.apiUrl}/${id}`, epi);
  }

  excluirEpi(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }

  /* =======================================================
     MÉTODOS - ENTREGAS DE EPIs (com baixa e estorno de estoque)
     ======================================================= */

  /** Lista as entregas; com colaboradorId devolve só as entregas daquele colaborador. */
  obterEntregas(colaboradorId?: number): Observable<EntregaEpi[]> {
    const params = colaboradorId == null ? undefined : { colaboradorId: String(colaboradorId) };
    return this.http.get<EntregaEpi[]>(this.apiEntregasUrl, { params });
  }

  registrarEntrega(entrega: EntregaEpiRequest): Observable<EntregaEpi> {
    return this.http.post<EntregaEpi>(this.apiEntregasUrl, entrega);
  }

  excluirEntrega(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiEntregasUrl}/${id}`);
  }
}
