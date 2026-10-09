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

export interface EntregaEpi {
  id?: number | string;
  colaborador: string;
  epi: string;
  data: string;
  assinatura: string;
}

@Injectable({
  providedIn: 'root',
})
export class EpisService {
  private apiUrl = `${environment.apiBaseUrl}/epis`;
  private apiEntregasUrl = 'http://localhost:3000/entregas-epis';

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
     MÉTODOS - REGISTRO DE ENTREGAS DE EPIs
     ======================================================= */

  obterEntregas(): Observable<EntregaEpi[]> {
    return this.http.get<EntregaEpi[]>(this.apiEntregasUrl);
  }

  registrarEntrega(entrega: EntregaEpi): Observable<EntregaEpi> {
    return this.http.post<EntregaEpi>(this.apiEntregasUrl, entrega);
  }
}
