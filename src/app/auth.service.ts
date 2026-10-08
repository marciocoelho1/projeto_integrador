import { Injectable } from '@angular/core';

export interface AuthenticatedUser {
  matricula: string;
  nomeExibicao: string;
}

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  private readonly LOGGED_KEY = 'usuario_logado';
  private readonly ROLE_KEY = 'usuario_perfil';
  private readonly USER_KEY = 'usuario_identidade';

  setSession(perfil: string, usuario: AuthenticatedUser): void {
    localStorage.setItem(this.LOGGED_KEY, 'true');
    localStorage.setItem(this.ROLE_KEY, perfil);
    localStorage.setItem(this.USER_KEY, JSON.stringify(usuario));
  }

  logout(): void {
    localStorage.removeItem(this.LOGGED_KEY);
    localStorage.removeItem(this.ROLE_KEY);
    localStorage.removeItem(this.USER_KEY);
  }

  isLoggedIn(): boolean {
    return localStorage.getItem(this.LOGGED_KEY) === 'true';
  }

  getRole(): string | null {
    return localStorage.getItem(this.ROLE_KEY);
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
