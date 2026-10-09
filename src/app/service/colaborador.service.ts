import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import {
  Colaborador,
  ColaboradorRequest
} from '../models/colaborador.model';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class ColaboradorService {
  private readonly http = inject(HttpClient);

  private readonly apiUrl =
    `${environment.apiBaseUrl}/colaboradores`;

  listar(): Observable<Colaborador[]> {
    return this.http.get<Colaborador[]>(this.apiUrl);
  }

  buscarPorId(id: number): Observable<Colaborador> {
    return this.http.get<Colaborador>(`${this.apiUrl}/${id}`);
  }

  criar(dados: ColaboradorRequest): Observable<Colaborador> {
    return this.http.post<Colaborador>(this.apiUrl, dados);
  }

  atualizar(
    id: number,
    dados: ColaboradorRequest
  ): Observable<Colaborador> {
    return this.http.put<Colaborador>(
      `${this.apiUrl}/${id}`,
      dados
    );
  }

  excluir(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
