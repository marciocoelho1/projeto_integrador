import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

export interface UsuarioApi {
  id: number;
  nomeCompleto: string;
  login: string;
  email: string;
  cpf: string;
  grupoId: number;
  grupo: string;
  status: 'Ativo' | 'Inativo';
  modulos: string[];
  criadoEm: string;
}

export interface UsuarioRequestApi {
  nomeCompleto: string;
  login: string;
  email: string;
  cpf: string;
  grupoId: number;
  status: 'Ativo' | 'Inativo';
  senha?: string | null;
}

export interface GrupoApi {
  id: number;
  nomenclatura: string;
  finalidade: string;
  modulos: string[];
}

export interface ModuloApi {
  chave: string;
  titulo: string;
  detalhe: string;
}

@Injectable({
  providedIn: 'root',
})
export class AcessoService {
  private readonly http = inject(HttpClient);
  private readonly usuariosUrl = `${environment.apiBaseUrl}/usuarios`;
  private readonly gruposUrl = `${environment.apiBaseUrl}/grupos`;
  private readonly modulosUrl = `${environment.apiBaseUrl}/modulos`;

  listarUsuarios(): Observable<UsuarioApi[]> {
    return this.http.get<UsuarioApi[]>(this.usuariosUrl);
  }

  criarUsuario(dados: UsuarioRequestApi): Observable<UsuarioApi> {
    return this.http.post<UsuarioApi>(this.usuariosUrl, dados);
  }

  atualizarUsuario(
    id: number,
    dados: UsuarioRequestApi,
  ): Observable<UsuarioApi> {
    return this.http.put<UsuarioApi>(`${this.usuariosUrl}/${id}`, dados);
  }

  alterarSenha(id: number, senha: string): Observable<void> {
    return this.http.put<void>(`${this.usuariosUrl}/${id}/senha`, { senha });
  }

  excluirUsuario(id: number): Observable<void> {
    return this.http.delete<void>(`${this.usuariosUrl}/${id}`);
  }

  listarGrupos(): Observable<GrupoApi[]> {
    return this.http.get<GrupoApi[]>(this.gruposUrl);
  }

  /** O back-end usa só o campo `modulos` nesta rota. */
  definirModulos(id: number, modulos: string[]): Observable<GrupoApi> {
    return this.http.put<GrupoApi>(`${this.gruposUrl}/${id}/modulos`, {
      modulos,
    });
  }

  listarModulos(): Observable<ModuloApi[]> {
    return this.http.get<ModuloApi[]>(this.modulosUrl);
  }
}
