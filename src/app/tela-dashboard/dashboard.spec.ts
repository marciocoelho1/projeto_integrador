import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting, HttpTestingController } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { Dashboard } from './dashboard';
import { DashboardIndicadores } from '../service/dashboard.service';

const INDICADORES: DashboardIndicadores = {
  colaboradores: { total: 16, ativos: 12, inativos: 3, afastados: 1 },
  certificacoes: { total: 7, ativas: 5, vencidas: 2, vencendoEm30Dias: 1 },
  epis: { emEstoque: 140, proximoVencimento: 12, vencidos: 6, entreguesUltimos30Dias: 9, totalTipos: 4 },
  treinamentos: { concluidos: 7, pendentes: 5, vencidos: 2, total: 10, porcentagem: 50 },
  alertas: [
    { tipo: 'EPI', mensagem: '6 unidade(s) de EPI com CA vencido no estoque.', criticidade: 'alta' },
    { tipo: 'Suporte', mensagem: '3 chamado(s) de suporte em andamento.', criticidade: 'media' },
  ],
  geradoEm: '2026-06-01T10:00:00-03:00',
};

describe('Dashboard - indicadores reais', () => {
  let http: HttpTestingController;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Dashboard],
      providers: [provideHttpClient(), provideHttpClientTesting()],
    }).compileComponents();
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    http.match((requisicao) => requisicao.url.includes('/api/relatorios/')).forEach((requisicao) => {
      requisicao.flush(new Blob(['ok'], { type: 'text/csv' }));
    });
    http.verify();
  });

  function montar() {
    const fixture = TestBed.createComponent(Dashboard);
    fixture.detectChanges();
    return fixture;
  }

  it('busca os indicadores no servidor ao abrir', () => {
    const fixture = montar();

    const requisicao = http.expectOne('http://localhost:8080/api/dashboard/indicadores');
    expect(requisicao.request.method).toBe('GET');

    requisicao.flush(INDICADORES);
    fixture.detectChanges();

    expect(fixture.nativeElement.textContent).toContain('12 de 16 colaborador(es) ativo(s)');
  });

  it('mostra os numeros reais e os alertas devolvidos pela API', () => {
    const fixture = montar();
    http.expectOne('http://localhost:8080/api/dashboard/indicadores').flush(INDICADORES);
    fixture.detectChanges();

    const tela = fixture.nativeElement.textContent;
    expect(tela).toContain('6 unidade(s) de EPI com CA vencido no estoque.');
    expect(tela).toContain('3 chamado(s) de suporte em andamento.');
    // certificações vencidas e o total do resumo
    expect(tela).toContain('Vencidas');
    // EPIs: saldo, o que vence em 30 dias e o que venceu
    expect(tela).toContain('140');
    expect(tela).toContain('12');
    expect(tela).toContain('6');
    // progresso dos treinamentos
    expect(tela).toContain('50%');
    expect(tela).toContain('Concluídos');

    // os números fixos do protótipo não podem sobrar na tela
    expect(tela).not.toContain('142');
    expect(tela).not.toContain('18');
  });

  it('classifica os alertas por criticidade e nao inventa numero quando falta resposta', () => {
    const fixture = montar();

    expect(fixture.nativeElement.querySelectorAll('.alert-item').length).toBe(0);
    http.expectOne('http://localhost:8080/api/dashboard/indicadores').flush(INDICADORES);
    fixture.detectChanges();

    const itens = Array.from(fixture.nativeElement.querySelectorAll('.alert-item')) as HTMLElement[];
    expect(itens.length).toBe(2);
    expect(itens[0].className).toContain('alert-item--alta');
    expect(itens[1].className).toContain('alert-item--media');
  });

  it('mostra o erro da API e volta a carregar quando o usuario pede', () => {
    const fixture = montar();

    http
      .expectOne('http://localhost:8080/api/dashboard/indicadores')
      .flush({ mensagem: 'Banco indisponível.' }, { status: 503, statusText: 'Service Unavailable' });
    fixture.detectChanges();

    expect(fixture.nativeElement.textContent).toContain('Banco indisponível.');

    const botao = fixture.nativeElement.querySelector('[data-acao="recarregar"]') as HTMLButtonElement;
    botao.click();
    http.expectOne('http://localhost:8080/api/dashboard/indicadores').flush(INDICADORES);
    fixture.detectChanges();

    expect(fixture.nativeElement.textContent).toContain('12 de 16 colaborador(es) ativo(s)');
  });

  it('exportar baixa o CSV gerado no servidor', () => {
    const conteudos: string[] = [];
    const blobOriginal = globalThis.Blob;
    const criarUrlOriginal = URL.createObjectURL;
    const revogarUrlOriginal = URL.revokeObjectURL;
    const clicarOriginal = HTMLAnchorElement.prototype.click;
    let nomeDoArquivo = '';

    (globalThis as any).Blob = class {
      constructor(partes: unknown[]) {
        conteudos.push(partes.join(''));
      }
    };
    (URL as any).createObjectURL = () => 'blob:teste';
    (URL as any).revokeObjectURL = () => undefined;
    HTMLAnchorElement.prototype.click = function (this: HTMLAnchorElement) {
      nomeDoArquivo = this.download;
    };

    try {
      const fixture = montar();
      http.expectOne('http://localhost:8080/api/dashboard/indicadores').flush(INDICADORES);
      fixture.detectChanges();

      const botao = fixture.nativeElement.querySelector('[data-acao="exportar"]') as HTMLButtonElement;
      botao.click();

      const requisicao = http.expectOne('http://localhost:8080/api/relatorios/dashboard.csv');
      expect(requisicao.request.method).toBe('GET');
      expect(requisicao.request.responseType).toBe('blob');
      requisicao.flush(new globalThis.Blob(['Categoria;Métrica;Valor']));
    } finally {
      (globalThis as any).Blob = blobOriginal;
      (URL as any).createObjectURL = criarUrlOriginal;
      (URL as any).revokeObjectURL = revogarUrlOriginal;
      HTMLAnchorElement.prototype.click = clicarOriginal;
    }

    expect(nomeDoArquivo).toBe('relatorio_dashboard.csv');
    expect(conteudos.join('')).toContain('Categoria;Métrica;Valor');
  });
});
