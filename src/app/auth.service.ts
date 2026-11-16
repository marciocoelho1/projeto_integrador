import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import { environment } from '../environments/environment';

export interface AuthenticatedUser {
  matricula: string;
  nomeExibicao: string;
}

export interface SessaoApi {
  id: number;
  login: string;
  nomeCompleto: string;
  grupo: string;
  modulos: string[];
}

export interface LoginApiResponse {
  token: string;
  expiraEm: string;
  usuario: SessaoApi;
}

/** Perfil usado pelos menus do layout ('admin' | 'colaborador'), derivado do grupo de acesso. */
export function perfilDoGrupo(grupo: string): string {
  return grupo.toLowerCase().includes('administrador') ? 'admin' : 'colaborador';
}

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  private readonly LOGGED_KEY = 'usuario_logado';
  private readonly ROLE_KEY = 'usuario_perfil';
  private readonly USER_KEY = 'usuario_identidade';
  private readonly TOKEN_KEY = 'usuario_token';
  private readonly MODULOS_KEY = 'usuario_modulos';

  private readonly http = inject(HttpClient);
  private readonly apiUrl = `${environment.apiBaseUrl}/auth`;

  setSession(
    perfil: string,
    usuario: AuthenticatedUser,
    token?: string,
    modulos?: string[],
  ): void {
    localStorage.setItem(this.LOGGED_KEY, 'true');
    localStorage.setItem(this.ROLE_KEY, perfil);
    localStorage.setItem(this.USER_KEY, JSON.stringify(usuario));

    if (token) {
      localStorage.setItem(this.TOKEN_KEY, token);
    }

    if (modulos) {
      localStorage.setItem(this.MODULOS_KEY, JSON.stringify(modulos));
    }
  }

  /** Autentica na API e guarda token, identidade, perfil e módulos liberados. */
  entrar(login: string, senha: string): Observable<LoginApiResponse> {
    return this.http
      .post<LoginApiResponse>(`${this.apiUrl}/login`, { login, senha })
      .pipe(
        tap((resposta) => {
          this.setSession(
            perfilDoGrupo(resposta.usuario.grupo),
            {
              matricula: resposta.usuario.login,
              nomeExibicao: resposta.usuario.nomeCompleto,
            },
            resposta.token,
            resposta.usuario.modulos,
          );
        }),
      );
  }

  /** Limpa a sessão local. Usado também pelo interceptor quando a API responde 401. */
  limparSessaoLocal(): void {
    localStorage.removeItem(this.LOGGED_KEY);
    localStorage.removeItem(this.ROLE_KEY);
    localStorage.removeItem(this.USER_KEY);
    localStorage.removeItem(this.TOKEN_KEY);
    localStorage.removeItem(this.MODULOS_KEY);
  }

  /** Encerra a sessão no servidor (se houver token) e limpa o navegador imediatamente. */
  logout(): void {
    const token = this.getToken();
    this.limparSessaoLocal();

    if (token) {
      this.http
        .post(
          `${this.apiUrl}/logout`,
          {},
          { headers: { Authorization: `Bearer ${token}` } },
        )
        .subscribe({ error: () => undefined });
    }
  }

  isLoggedIn(): boolean {
    return localStorage.getItem(this.LOGGED_KEY) === 'true';
  }

  getRole(): string | null {
    return localStorage.getItem(this.ROLE_KEY);
  }

  getToken(): string | null {
    return localStorage.getItem(this.TOKEN_KEY);
  }

  getModulos(): string[] {
    const stored = localStorage.getItem(this.MODULOS_KEY);

    if (!stored) {
      return [];
    }

    try {
      const modulos = JSON.parse(stored);
      return Array.isArray(modulos) ? (modulos as string[]) : [];
    } catch {
      return [];
    }
  }

  getCurrentUser(): AuthenticatedUser | null {
    if (!this.isLoggedIn()) {
      return null;
    }

    const storedUser = localStorage.getItem(this.USER_KEY);

    if (!storedUser) {
      return null;
    }

    try {
      const user = JSON.parse(storedUser) as Partial<AuthenticatedUser>;
      const matricula = user.matricula?.trim();
      const nomeExibicao = user.nomeExibicao?.trim();

      if (!matricula || !nomeExibicao) {
        return null;
      }

      return { matricula, nomeExibicao };
    } catch {
      return null;
    }
  }
}
