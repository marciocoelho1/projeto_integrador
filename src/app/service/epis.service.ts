import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';


export interface Epi {
  id?: string;
  descricao: string;
  quantidade: number;
  inclusao: string;
  validade: string;
  ca: string;
}

export interface EntregaEpi {
  id?: number | string;
  colaborador: string;
  epi: string;
  data: string;
  assinatura: string;
}

@Injectable({
  providedIn: 'root'
})
export class EpisService {
  private apiUrl = 'http://localhost:3000/epis';
  private apiEntregasUrl = 'http://localhost:3000/entregas-epis';

  constructor(private http: HttpClient) {}

  /* =======================================================
     MÉTODOS - GESTÃO DE ESTOQUE / CADASTRO DE EPIs
     ======================================================= */

  obterEpis(): Observable<Epi[]> {
    return this.http.get<Epi[]>(this.apiUrl);
  }

  obterEpiPorId(id: string): Observable<Epi> {
    return this.http.get<Epi>(`${this.apiUrl}/${id}`);
  }

  cadastrarEpi(epi: Epi): Observable<Epi> {
    return this.http.post<Epi>(this.apiUrl, epi);
  }

  atualizarEpi(id: string, epi: Epi): Observable<Epi> {
    return this.http.put<Epi>(`${this.apiUrl}/${id}`, epi);
  }

  excluirEpi(id: string): Observable<void> {
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