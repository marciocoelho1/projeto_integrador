import { TestBed } from '@angular/core/testing';
import { AuthService } from './auth.service';

describe('AuthService', () => {
  let service: AuthService;

  beforeEach(() => {
    localStorage.clear();
    service = TestBed.inject(AuthService);
  });

  afterEach(() => {
    localStorage.clear();
  });

  it('persiste e recupera a identidade autenticada de forma tipada', () => {
    service.setSession('colaborador', {
      matricula: 'colaborador',
      nomeExibicao: 'Colaborador',
    });

    expect(service.isLoggedIn()).toBe(true);
    expect(service.getRole()).toBe('colaborador');
    expect(service.getCurrentUser()).toEqual({
      matricula: 'colaborador',
      nomeExibicao: 'Colaborador',
    });
  });

  it('remove todos os dados da sessão durante o logout', () => {
    service.setSession('admin', {
      matricula: 'admin',
      nomeExibicao: 'Administrador TST',
    });

    service.logout();

    expect(service.isLoggedIn()).toBe(false);
    expect(service.getRole()).toBeNull();
    expect(service.getCurrentUser()).toBeNull();
    expect(localStorage.getItem('usuario_identidade')).toBeNull();
  });

  it('rejeita uma identidade armazenada inválida', () => {
    localStorage.setItem('usuario_logado', 'true');
    localStorage.setItem('usuario_identidade', '{valor-invalido');

    expect(service.getCurrentUser()).toBeNull();

    localStorage.setItem(
      'usuario_identidade',
      JSON.stringify({ matricula: ' ', nomeExibicao: 'Colaborador' }),
    );

    expect(service.getCurrentUser()).toBeNull();
  });
});
