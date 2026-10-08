import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';
import { AuthService } from '../auth.service';
import { LayoutPadrao } from './layout-padrao';

describe('LayoutPadrao', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  afterEach(() => {
    localStorage.clear();
  });

  it('remove a sessão e a identidade antes de navegar para o login', () => {
    const navigations: string[][] = [];
    const router = {
      navigate(commands: string[]): Promise<boolean> {
        expect(localStorage.getItem('usuario_logado')).toBeNull();
        expect(localStorage.getItem('usuario_perfil')).toBeNull();
        expect(localStorage.getItem('usuario_identidade')).toBeNull();
        navigations.push(commands);
        return Promise.resolve(true);
      },
    };

    TestBed.configureTestingModule({
      imports: [LayoutPadrao],
      providers: [{ provide: Router, useValue: router }],
    });

    const authService = TestBed.inject(AuthService);
    authService.setSession('colaborador', {
      matricula: 'colaborador',
      nomeExibicao: 'Colaborador',
    });
    const component = TestBed.createComponent(LayoutPadrao).componentInstance;
    const event = new Event('click', { cancelable: true });

    component.sair(event);

    expect(event.defaultPrevented).toBe(true);
    expect(navigations).toEqual([['/login']]);
  });
});
