import { TestBed } from '@angular/core/testing';
import { AuthenticatedUser, AuthService } from '../auth.service';
import { ToastService } from '../service/toast.service';
import { HelpSupportComponent, SupportRequest } from './ajuda-suporte-colaborador';

class AuthServiceStub {
  currentUser: AuthenticatedUser | null = {
    matricula: 'colaborador',
    nomeExibicao: 'Colaborador',
  };

  getCurrentUser(): AuthenticatedUser | null {
    return this.currentUser;
  }
}

class ToastServiceStub {
  readonly errors: string[] = [];
  readonly successes: string[] = [];

  error(message: string): void {
    this.errors.push(message);
  }

  success(message: string): void {
    this.successes.push(message);
  }
}

describe('HelpSupportComponent', () => {
  let authService: AuthServiceStub;
  let toastService: ToastServiceStub;

  beforeEach(async () => {
    authService = new AuthServiceStub();
    toastService = new ToastServiceStub();

    await TestBed.configureTestingModule({
      imports: [HelpSupportComponent],
      providers: [
        { provide: AuthService, useValue: authService },
        { provide: ToastService, useValue: toastService },
      ],
    }).compileComponents();
  });

  it('rejeita uma solicitação com descrição vazia', () => {
    const component = TestBed.createComponent(HelpSupportComponent).componentInstance;
    const initialCount = component.requests().length;

    component.ticketDescription = '   ';
    component.handleSubmit();

    expect(component.requests()).toHaveLength(initialCount);
    expect(toastService.errors).toContain('Preencha a descrição da solicitação.');
  });

  it('associa uma nova solicitação à matrícula e ao nome do usuário autenticado', () => {
    const component = TestBed.createComponent(HelpSupportComponent).componentInstance;

    component.ticketType = 'Reportar Erro';
    component.ticketDescription = '  Não consigo abrir o certificado.  ';
    component.handleSubmit();

    expect(component.requests()[0]).toEqual(
      expect.objectContaining({
        type: 'Erro',
        description: 'Não consigo abrir o certificado.',
        ownerMatricula: 'colaborador',
        user: 'Colaborador',
      }),
    );
    expect(toastService.successes).toContain('Solicitação enviada com sucesso!');
  });

  it('exibe somente as solicitações pertencentes à matrícula autenticada', () => {
    const fixture = TestBed.createComponent(HelpSupportComponent);
    const requests: SupportRequest[] = [
      {
        id: 10,
        type: 'Ajuda',
        description: 'Solicitação própria',
        ownerMatricula: 'colaborador',
        user: 'Colaborador',
        status: 'Em andamento',
      },
      {
        id: 11,
        type: 'Erro',
        description: 'Solicitação de outro usuário',
        ownerMatricula: 'outro-usuario',
        user: 'Outro usuário',
        status: 'Concluída',
      },
    ];

    fixture.componentInstance.requests.set(requests);
    fixture.detectChanges();

    const tableText = fixture.nativeElement.querySelector('tbody').textContent as string;
    expect(tableText).toContain('Solicitação própria');
    expect(tableText).not.toContain('Solicitação de outro usuário');
  });

  it('não exibe nem envia solicitações sem uma identidade autenticada válida', () => {
    const fixture = TestBed.createComponent(HelpSupportComponent);
    const component = fixture.componentInstance;
    const initialCount = component.requests().length;
    authService.currentUser = null;

    component.ticketDescription = 'Solicitação sem identidade';
    component.handleSubmit();
    fixture.detectChanges();

    expect(component.requests()).toHaveLength(initialCount);
    expect(fixture.nativeElement.querySelector('tbody').textContent).toContain(
      'Nenhuma solicitação encontrada.',
    );
    expect(toastService.errors).toContain(
      'Não foi possível identificar o usuário autenticado. Entre novamente.',
    );
  });
});
