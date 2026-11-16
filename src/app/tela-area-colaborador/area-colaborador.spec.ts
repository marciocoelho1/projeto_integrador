import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting, HttpTestingController } from '@angular/common/http/testing';
import { AreaColaborador } from './area-colaborador';

// Observação de teste: a aplicação é zoneless (não há zone.js no bundle), então
// fixture.detectChanges() não redesenha o DOM depois que as respostas HTTP chegam — o DOM
// fica no estado do primeiro render. Por isso as entregas reais são verificadas no estado do
// componente e as asserções de DOM ficam na estrutura fixa da tabela (cabeçalhos, colspan).

const COLABORADOR = {
  id: 7,
  matricula: 'colaborador',
  nome: 'Colaborador Teste',
  cpf: '12345678900',
  email: 'colaborador@essenza.com.br',
  cargo: 'Operador de Caixa',
  setor: 'Frente de Loja',
  status: 'Ativo',
};

const ENTREGAS = [
  {
    id: 11,
    colaboradorId: 7,
    colaborador: 'Colaborador Teste',
    matricula: 'colaborador',
    epiId: 3,
    epi: 'Capacete de Segurança',
    ca: '498',
    quantidade: 1,
    dataEntrega: '2026-06-01',
    assinatura: 'Colaborador Teste',
  },
  {
    id: 12,
    colaboradorId: 7,
    colaborador: 'Colaborador Teste',
    matricula: 'colaborador',
    epiId: 4,
    epi: 'Óculos de Segurança',
    ca: '18103',
    quantidade: 2,
    dataEntrega: '2026-05-20',
    assinatura: 'Colaborador Teste',
  },
];

/** Responde as duas chamadas do portal: a lista de colaboradores e as entregas do vínculo. */
function responderApi(colaboradores: unknown[], entregas: unknown[], colaboradorId = 7) {
  const http = TestBed.inject(HttpTestingController);
  http.expectOne('http://localhost:8080/api/colaboradores').flush(colaboradores);
  http
    .expectOne(`http://localhost:8080/api/entregas-epis?colaboradorId=${colaboradorId}`)
    .flush(entregas);
}

describe('AreaColaborador', () => {
  beforeEach(async () => {
    localStorage.setItem('usuario_logado', 'true');
    localStorage.setItem(
      'usuario_identidade',
      JSON.stringify({ matricula: 'colaborador', nomeExibicao: 'Colaborador Teste' }),
    );
    await TestBed.configureTestingModule({
      imports: [AreaColaborador],
      providers: [provideHttpClient(), provideHttpClientTesting()],
    }).compileComponents();
  });

  afterEach(() => {
    TestBed.inject(HttpTestingController).verify();
    localStorage.clear();
  });

  it('busca as entregas reais pelo colaborador casado com a matrícula do login', () => {
    const fixture = TestBed.createComponent(AreaColaborador);
    fixture.detectChanges();
    responderApi([COLABORADOR], ENTREGAS);

    const component = fixture.componentInstance;
    const ids = component.meusEpis.map((epi) => epi.id);

    expect(component.meusEpis).toEqual([
      {
        id: '11',
        nome: 'Capacete de Segurança',
        quantidade: 1,
        ca: '498',
        dataEntrega: '2026-06-01',
        assinatura: 'Colaborador Teste',
      },
      {
        id: '12',
        nome: 'Óculos de Segurança',
        quantidade: 2,
        ca: '18103',
        dataEntrega: '2026-05-20',
        assinatura: 'Colaborador Teste',
      },
    ]);
    expect(new Set(ids).size).toBe(ids.length);
    expect(component.meusEpis.every((epi) => epi.quantidade > 0)).toBe(true);
    expect(component.resumo.epis).toBe(2);
    expect(component.avisoEpis).toBe('');

    const tables = fixture.nativeElement.querySelectorAll('table') as NodeListOf<HTMLTableElement>;
    const epiTable = tables.item(tables.length - 1);
    const headers = Array.from(epiTable.querySelectorAll('th')).map((header) =>
      header.textContent?.trim(),
    );
    expect(headers).toEqual([
      'ID',
      'EPI',
      'Quantidade',
      'CA',
      'Data de Entrega',
      'Assinatura do Termo',
    ]);
  });

  it('casa o colaborador pelo e-mail quando o login é um e-mail', () => {
    localStorage.setItem(
      'usuario_identidade',
      JSON.stringify({ matricula: 'COLABORADOR@ESSENZA.COM.BR', nomeExibicao: 'Colaborador Teste' }),
    );
    const fixture = TestBed.createComponent(AreaColaborador);
    fixture.detectChanges();
    responderApi([{ ...COLABORADOR, email: 'colaborador@essenza.com.br' }], [ENTREGAS[0]]);

    expect(fixture.componentInstance.meusEpis.map((epi) => epi.id)).toEqual(['11']);
  });

  it('faz o estado vazio ocupar as seis colunas da tabela de EPIs', () => {
    const fixture = TestBed.createComponent(AreaColaborador);
    fixture.detectChanges();
    responderApi([COLABORADOR], []);

    const emptyCell = fixture.nativeElement.querySelector(
      'main > section.sst-card tbody td',
    ) as HTMLTableCellElement;

    expect(emptyCell.colSpan).toBe(6);
    expect(emptyCell.textContent).toContain('Nenhum EPI registrado');
    expect(fixture.componentInstance.avisoEpis).toBe('Nenhum EPI registrado no momento.');
    expect(fixture.componentInstance.resumo.epis).toBe(0);
  });

  it('explica o estado vazio em vez de inventar dados quando o login não tem vínculo', () => {
    const fixture = TestBed.createComponent(AreaColaborador);
    fixture.detectChanges();
    const http = TestBed.inject(HttpTestingController);
    http
      .expectOne('http://localhost:8080/api/colaboradores')
      .flush([{ ...COLABORADOR, matricula: 'outra', email: 'outra@essenza.com.br' }]);

    expect(fixture.componentInstance.meusEpis).toEqual([]);
    expect(fixture.componentInstance.resumo.epis).toBe(0);
    expect(fixture.componentInstance.avisoEpis).toContain('SESMT');
    expect(http.match((req) => req.url.includes('entregas-epis')).length).toBe(0);
  });

  it('apresenta o prazo como alerta acessível e preserva o link do material', () => {
    const fixture = TestBed.createComponent(AreaColaborador);
    fixture.detectChanges();
    responderApi([COLABORADOR], ENTREGAS);

    const deadline = fixture.nativeElement.querySelector(
      '.area-colaborador__deadline',
    ) as HTMLElement;
    const icon = deadline.querySelector('svg') as SVGElement;
    const link = fixture.nativeElement.querySelector(
      '.area-colaborador__material .sst-btn-link',
    ) as HTMLAnchorElement;
    const detailsGrid = fixture.nativeElement.querySelector(
      '.area-colaborador__details-grid',
    ) as HTMLElement;

    expect(deadline.getAttribute('role')).toBe('status');
    expect(deadline.getAttribute('aria-label')).toContain('Alerta: Prazo de conclusão:');
    expect(icon.getAttribute('aria-hidden')).toBe('true');
    expect(link.target).toBe('_blank');
    expect(link.rel).toBe('noopener noreferrer');
    expect(detailsGrid.querySelectorAll(':scope > .sst-card')).toHaveLength(2);
  });
});
