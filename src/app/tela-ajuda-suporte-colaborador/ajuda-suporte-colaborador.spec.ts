import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting, HttpTestingController } from '@angular/common/http/testing';
import { ToastService } from '../service/toast.service';
import { HelpSupportComponent } from './ajuda-suporte-colaborador';

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

const chamados = (request: { url: string }) => request.url.includes('/chamados');

describe('HelpSupportComponent', () => {
  let toastService: ToastServiceStub;

  beforeEach(async () => {
    toastService = new ToastServiceStub();

    await TestBed.configureTestingModule({
      imports: [HelpSupportComponent],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: ToastService, useValue: toastService },
      ],
    }).compileComponents();
  });

  afterEach(() => TestBed.inject(HttpTestingController).verify());

  it('carrega somente os chamados do usuário da sessão (GET ?meus=true)', () => {
    const fixture = TestBed.createComponent(HelpSupportComponent);
    fixture.detectChanges();

    const http = TestBed.inject(HttpTestingController);
    const listar = http.expectOne((request) => chamados(request) && request.method === 'GET');
    expect(listar.request.params.get('meus')).toBe('true');
    listar.flush([
      {
        id: 1,
        tipo: 'Ajuda',
        descricao: 'Dúvida sobre renovação de NR-10',
        usuarioId: 7,
        solicitante: 'Colaborador',
        status: 'Em andamento',
        abertoEm: '2026-01-01T10:00:00Z',
        concluidoEm: null,
      },
    ]);
    fixture.detectChanges();

    const tableText = fixture.nativeElement.querySelector('tbody').textContent as string;
    expect(tableText).toContain('Dúvida sobre renovação de NR-10');
    expect(tableText).toContain('Colaborador');
  });

  it('rejeita uma solicitação com descrição vazia sem chamar a API', () => {
    const component = TestBed.createComponent(HelpSupportComponent).componentInstance;

    component.ticketDescription = '   ';
    component.handleSubmit();

    TestBed.inject(HttpTestingController).expectNone((request) => request.method === 'POST');
    expect(toastService.errors).toContain('Preencha a descrição da solicitação.');
  });

  it('envia a solicitação (POST) e a adiciona à lista', () => {
    const fixture = TestBed.createComponent(HelpSupportComponent);
    const component = fixture.componentInstance;
    fixture.detectChanges();

    TestBed.inject(HttpTestingController)
      .expectOne((request) => chamados(request) && request.method === 'GET')
      .flush([]);

    component.ticketType = 'Reportar Erro';
    component.ticketDescription = '  Não consigo abrir o certificado.  ';
    component.handleSubmit();

    const post = TestBed.inject(HttpTestingController)
      .expectOne((request) => chamados(request) && request.method === 'POST');
    expect(post.request.body).toEqual({
      tipo: 'Erro',
      descricao: 'Não consigo abrir o certificado.',
    });
    post.flush({
      id: 9,
      tipo: 'Erro',
      descricao: 'Não consigo abrir o certificado.',
      usuarioId: 7,
      solicitante: 'Colaborador',
      status: 'Em andamento',
      abertoEm: '2026-01-02T10:00:00Z',
      concluidoEm: null,
    });

    expect(component.requests()[0]).toEqual(
      expect.objectContaining({
        id: 9,
        type: 'Erro',
        description: 'Não consigo abrir o certificado.',
        user: 'Colaborador',
        status: 'Em andamento',
      }),
    );
    expect(toastService.successes).toContain('Solicitação enviada com sucesso!');
  });

  it('avisa quando a API falha ao carregar as solicitações', () => {
    const fixture = TestBed.createComponent(HelpSupportComponent);
    fixture.detectChanges();

    TestBed.inject(HttpTestingController)
      .expectOne((request) => chamados(request) && request.method === 'GET')
      .error(new ProgressEvent('error'));

    expect(toastService.errors.length).toBeGreaterThan(0);
    expect(fixture.componentInstance.requests()).toEqual([]);
  });
});
