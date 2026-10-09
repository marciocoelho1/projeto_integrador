import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Treinamento, TreinamentoRequest } from '../models/treinamento.model';
import { environment } from '../../environments/environment';
@Injectable({ providedIn: 'root' })
export class TreinamentoService {
  private readonly http = inject(HttpClient);
  private readonly url = `${environment.apiBaseUrl}/treinamentos`;
  listar() {
    return this.http.get<Treinamento[]>(this.url);
  }
  buscarPorId(id: number) {
    return this.http.get<Treinamento>(`${this.url}/${id}`);
  }
  criar(dados: TreinamentoRequest) {
    return this.http.post<Treinamento>(this.url, dados);
  }
  atualizar(id: number, dados: TreinamentoRequest) {
    return this.http.put<Treinamento>(`${this.url}/${id}`, dados);
  }
  excluir(id: number) {
    return this.http.delete<void>(`${this.url}/${id}`);
  }
}
