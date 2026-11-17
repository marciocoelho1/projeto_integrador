import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting, HttpTestingController } from '@angular/common/http/testing';
import { provideRouter } from '@angular/router';
import { TestBed } from '@angular/core/testing';
import { Dashboard } from './dashboard';
import { DashboardIndicadores } from '../service/dashboard.service';

/** Datas relativas a hoje: o painel trabalha com janelas de tempo, não com data fixa. */
function diasAtras(dias: number): string {
  const data = new Date();
  data.setDate(data.getDate() - dias);
  const mes = String(data.getMonth() + 1).padStart(2, '0');
  const dia = String(data.getDate()).padStart(2, '0');

  return `${data.getFullYear()}-${mes}-${dia}`;
}

function diasFrente(dias: number): string {
  const data = new Date();
  data.setDate(data.getDate() + dias);
  const mes = String(data.getMonth() + 1).padStart(2, '0');
  const dia = String(data.getDate()).padStart(2, '0');

  return `${data.getFullYear()}-${mes}-${dia}`;
}

function comoDataBr(iso: string): string {
  const [ano, mes, dia] = iso.split('-');

  return `${dia}/${mes}/${ano}`;
}

function comoDataHoraBr(data: Date): string {
  const dia = String(data.getDate()).padStart(2, '0');
  const mes = String(data.getMonth() + 1).padStart(2, '0');
  const hora = String(data.getHours()).padStart(2, '0');
  const minuto = String(data.getMinutes()).padStart(2, '0');

  return `${dia}/${mes} · ${hora}:${minuto}`;
}

const INDICADORES: DashboardIndicadores = {
  colaboradores: { total: 16, ativos: 12, inativos: 3, afastados: 1 },
  certificacoes: { total: 7, ativas: 5, vencidas: 2, vencendoEm30Dias: 1 },
  epis: {
    emEstoque: 140,
    proximoVencimento: 12,
    vencidos: 6,
    entreguesUltimos30Dias: 9,
    totalTipos: 4,
  },
  treinamentos: { concluidos: 7, pendentes: 5, vencidos: 2, total: 10, porcentagem: 50 },
  alertas: [
    {
      tipo: 'EPI',
      mensagem: '6 unidade(s) de EPI com CA vencido no estoque.',
      criticidade: 'alta',
    },
    { tipo: 'Suporte', mensagem: '3 chamado(s) de suporte em andamento.', criticidade: 'media' },
  ],
  geradoEm: '2026-06-01T10:00:00-03:00',
};

const COLABORADORES = [
  {
    id: 1,
    matricula: '001',
    nome: 'Ana Ribeiro',
    cpf: '1',
    email: 'a@b.com',
    cargo: 'Operadora de Caixa',
    setor: 'Frente de Loja',
    status: 'Ativo' as const,
  },
  {
    id: 2,
    matricula: '002',
    nome: 'Bruno Salles',
    cpf: '2',
    email: 'b@b.com',
    cargo: 'Repositor',
    setor: 'Mercearia',
    status: 'Ativo' as const,
  },
  {
    id: 3,
    matricula: '003',
    nome: 'Carla Mendes',
    cpf: '3',
    email: 'c@b.com',
    cargo: 'Açougueira',
    setor: 'Açougue',
    status: 'Afastado' as const,
  },
  {
    id: 4,
    matricula: '004',
    nome: 'Diego Alves',
    cpf: '4',
    email: 'd@b.com',
    cargo: 'Repositor',
    setor: 'Mercearia',
    status: 'Ativo' as const,
  },
];

const EPIS = [
  {
    id: 1,
    descricao: 'Protetor Auricular',
    quantidade: 2,
    inclusao: '2025-01-10',
    validade: '2025-01-10',
    ca: '12345',
  },
  {
    id: 2,
    descricao: 'Luva Nitrílica',
    quantidade: 3,
    inclusao: '2025-01-10',
    validade: '2099-01-10',
    ca: '39012',
  },
  {
    id: 3,
    descricao: 'Botina de Segurança',
    quantidade: 40,
    inclusao: '2025-01-10',
    validade: '2099-01-10',
    ca: '215',
  },
];

const ENTREGA_RECENTE = diasAtras(5);
const ENTREGA_ANTERIOR = diasAtras(20);

const ENTREGAS = [
  {
    id: 1,
    colaboradorId: 1,
    colaborador: 'Ana Ribeiro',
    matricula: '001',
    epiId: 2,
    epi: 'Luva Nitrílica',
    ca: '39012',
    quantidade: 2,
    dataEntrega: ENTREGA_RECENTE,
    assinatura: 'Ana Ribeiro',
  },
  {
    id: 2,
    colaboradorId: 2,
    colaborador: 'Bruno Salles',
    matricula: '002',
    epiId: 3,
    epi: 'Botina de Segurança',
    ca: '215',
    quantidade: 1,
    dataEntrega: ENTREGA_ANTERIOR,
    assinatura: '',
  },
];

const LOG = new Date();

const CHAMADOS = [
  {
    id: 1,
    tipo: 'Ajuda' as const,
    descricao: 'Dúvida',
    usuarioId: 1,
    solicitante: 'Ana',
    status: 'Em andamento' as const,
    abertoEm: '2026-05-02T10:00:00-03:00',
    concluidoEm: null,
  },
  {
    id: 2,
    tipo: 'Erro' as const,
    descricao: 'Falha',
    usuarioId: 1,
    solicitante: 'Ana',
    status: 'Concluída' as const,
    abertoEm: '2026-05-01T10:00:00-03:00',
    concluidoEm: LOG.toISOString(),
  },
];

const TREINAMENTOS = [
  {
    id: 1,
    codigo: 'T1',
    nome: 'Trabalho em Altura',
    classificacao: 'NR',
    nr: 'NR-35',
    cargaHoraria: '8h',
    validadeMeses: 12,
    status: 'Ativo' as const,
  },
  {
    id: 2,
    codigo: 'T2',
    nome: 'EPI',
    classificacao: 'NR',
    nr: 'NR-06',
    cargaHoraria: '4h',
    validadeMeses: 12,
    status: 'Ativo' as const,
  },
];

const VINCULOS = [
  {
    id: 1,
    colaboradorId: 1,
    treinamentoId: 1,
    dataConclusao: '2024-01-01',
    status: 'Concluído' as const,
    colaborador: 'Ana Ribeiro',
    cargo: 'Operadora de Caixa',
    treinamento: 'Trabalho em Altura',
    validade: diasAtras(30),
  },
  {
    id: 2,
    colaboradorId: 3,
    treinamentoId: 1,
    dataConclusao: '2024-01-01',
    status: 'Concluído' as const,
    colaborador: 'Carla Mendes',
    cargo: 'Açougueira',
    treinamento: 'Trabalho em Altura',
    validade: diasAtras(60),
  },
  {
    id: 3,
    colaboradorId: 2,
    treinamentoId: 2,
    dataConclusao: null,
    status: 'Pendente' as const,
    colaborador: 'Bruno Salles',
    cargo: 'Repositor',
    treinamento: 'EPI',
    validade: null,
  },
  {
    id: 4,
    colaboradorId: 4,
    treinamentoId: 2,
    dataConclusao: '2025-01-01',
    status: 'Concluído' as const,
    colaborador: 'Diego Alves',
    cargo: 'Repositor',
    treinamento: 'EPI',
    validade: diasFrente(200),
  },
  {
    id: 5,
    colaboradorId: 1,
    treinamentoId: 2,
    dataConclusao: '2025-01-01',
    status: 'Concluído' as const,
    colaborador: 'Ana Ribeiro',
    cargo: 'Operadora de Caixa',
    treinamento: 'EPI',
    validade: diasFrente(10),
  },
];

const LOGS = [
  {
    id: 1,
    dataHora: LOG.toISOString(),
    usuarioId: 1,
    usuario: 'Admin',
    modulo: 'epis',
    acao: 'CRIACAO' as const,
    descricao: 'Entrega de EPI registrada.',
    metodo: 'POST',
    caminho: '/api/entregas-epis',
    statusHttp: 201,
  },
];

/** Todas as fontes que o dashboard carrega em paralelo. */
const FONTES: { url: string; corpo: unknown }[] = [
  { url: 'http://localhost:8080/api/dashboard/indicadores', corpo: INDICADORES },
  { url: 'http://localhost:8080/api/colaboradores', corpo: COLABORADORES },
  { url: 'http://localhost:8080/api/epis', corpo: EPIS },
  { url: 'http://localhost:8080/api/entregas-epis', corpo: ENTREGAS },
  { url: 'http://localhost:8080/api/chamados', corpo: CHAMADOS },
  { url: 'http://localhost:8080/api/vinculos', corpo: VINCULOS },
  { url: 'http://localhost:8080/api/treinamentos', corpo: TREINAMENTOS },
  { url: 'http://localhost:8080/api/auditoria', corpo: LOGS },
];

describe('Dashboard - indicadores reais', () => {
  let http: HttpTestingController;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Dashboard],
      providers: [provideHttpClient(), provideHttpClientTesting(), provideRouter([])],
    }).compileComponents();
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    // O CSV do relatório é gerado no servidor; nos testes ele é só descartado.
    http
      .match((requisicao) => requisicao.url.includes('/api/relatorios/'))
      .forEach((requisicao) => {
        requisicao.flush(new Blob(['ok'], { type: 'text/csv' }));
      });
    http.verify({ ignoreCancelled: true });
  });

  function montar() {
    const fixture = TestBed.createComponent(Dashboard);
    fixture.detectChanges();
    return fixture;
  }

  /**
   * Responde as oito fontes do painel. Depois de uma carga que falhou, as requisições antigas
   * continuam abertas como canceladas: elas são ignoradas aqui.
   */
  function responderTudo() {
    for (const fonte of FONTES) {
      const pendente = http
        .match((requisicao) => requisicao.url === fonte.url)
        .find((requisicao) => !requisicao.cancelled);

      expect(pendente, `requisição pendente para ${fonte.url}`).toBeTruthy();
      expect(pendente?.request.method).toBe('GET');
      pendente?.flush(fonte.corpo as object);
    }
  }

  it('busca os indicadores e as listas do painel ao abrir', () => {
    const fixture = montar();

    expect(fixture.nativeElement.textContent).toContain('Carregando indicadores…');

    responderTudo();
    fixture.detectChanges();

    expect(fixture.nativeElement.textContent).toContain('12 de 16 colaborador(es) ativo(s)');
  });

  it('monta os KPI com os numeros reais da API', () => {
    const fixture = montar();
    responderTudo();
    fixture.detectChanges();

    const tela = fixture.nativeElement.textContent;

    // Colaboradores ativos (12 de 16) e o detalhe de afastados/inativos
    expect(tela).toContain('Colaboradores ativos');
    expect(tela).toContain('/ 16');
    expect(tela).toContain('1 afastado');
    expect(tela).toContain('3 inativos');
    // EPIs em estoque e os dois tipos em nível crítico (2 e 3 unidades)
    expect(tela).toContain('140');
    expect(tela).toContain('2 tipos em nível crítico');
    // Certificações ativas/vencidas
    expect(tela).toContain('Certificações');
    expect(tela).toContain('2 vencidas');
    // Chamados abertos e concluídos no mês
    expect(tela).toContain('Chamados de suporte');
    expect(tela).toContain('1 aberto');
    expect(tela).toContain('1 concluído(s) no mês');

    // os números fixos do protótipo não podem sobrar na tela
    expect(tela).not.toContain('142');
  });

  it('mostra as pendencias com criticidade e o link para a tela que resolve', () => {
    const fixture = montar();
    responderTudo();
    fixture.detectChanges();

    const itens = Array.from(
      fixture.nativeElement.querySelectorAll('.attention-item'),
    ) as HTMLElement[];

    expect(itens.length).toBe(2);
    expect(itens[0].className).toContain('attention-item--alta');
    expect(itens[0].textContent).toContain('6 unidade(s) de EPI com CA vencido no estoque.');
    expect(itens[0].querySelector('a')?.getAttribute('href')).toBe('/epis');
    expect(itens[1].className).toContain('attention-item--media');
    expect(itens[1].querySelector('a')?.getAttribute('href')).toBe('/ajuda-suporte');
    expect(fixture.nativeElement.textContent).toContain('2 pendências abertas que exigem decisão');
  });

  it('calcula conformidade, heatmap por NR e setor e o quadro por setor', () => {
    const fixture = montar();
    responderTudo();
    fixture.detectChanges();

    const tela = fixture.nativeElement.textContent;

    // Conformidade: 1 em dia, 1 a vencer, 2 vencidos e 1 pendente em 5 vínculos = 20%
    expect(tela).toContain('Conformidade de treinamentos');
    expect(tela).toContain('20%');
    expect(tela).toContain('1 de 5 vínculos em dia');
    const legenda = Array.from(
      (fixture.nativeElement.querySelector('.legend') as HTMLElement).querySelectorAll('span'),
    ) as HTMLElement[];
    expect(legenda.map((item) => item.textContent?.trim())).toEqual([
      '1 em dia',
      '1 a vencer',
      '2 vencido(s)',
      '1 sem conclusão',
    ]);

    // Conformidade por NR: NR-35 só tem vencidos, NR-06 tem 1 em dia de 3
    const porNr = Array.from(
      fixture.nativeElement.querySelectorAll('.bento-comp .list__item'),
    ) as HTMLElement[];
    expect(porNr.map((linha) => linha.textContent?.replace(/\s+/g, ' ').trim())).toEqual([
      'NR-06 1 em dia · 0 vencidos 33%',
      'NR-35 0 em dia · 2 vencidos 0%',
    ]);

    // Heatmap: os vínculos vencidos aparecem no setor de cada colaborador
    const heatmap = fixture.nativeElement.querySelector('.heatmap');
    expect(heatmap).toBeTruthy();
    expect(heatmap.textContent).toContain('Açougue');
    expect(heatmap.querySelectorAll('.heat-linha-total').length).toBe(1);

    // Colaboradores por setor: Mercearia tem 2 dos 4 colaboradores
    const setores = Array.from(fixture.nativeElement.querySelectorAll('.hbar')) as HTMLElement[];
    expect(
      setores.map((linha) => linha.querySelector('.hbar__label')?.textContent?.trim()),
    ).toEqual(['Mercearia', 'Açougue', 'Frente de Loja']);
    expect(setores.map((linha) => linha.querySelector('.hbar__val')?.textContent?.trim())).toEqual([
      '2',
      '1',
      '1',
    ]);
  });

  it('lista EPIs criticos, entregas dos ultimos 6 meses e a atividade recente', () => {
    const fixture = montar();
    responderTudo();
    fixture.detectChanges();

    const tela = fixture.nativeElement.textContent;

    // Estoque crítico: só o que está no limite ou abaixo de 5 unidades
    const criticos = Array.from(
      fixture.nativeElement.querySelectorAll('.bento-epi-list .list__item'),
    ) as HTMLElement[];
    expect(criticos.length).toBe(2);
    expect(criticos[0].textContent).toContain('Protetor Auricular');
    expect(criticos[0].textContent).toContain('Vencido');
    expect(criticos[1].textContent).toContain('Luva Nitrílica');
    expect(criticos[1].textContent).toContain('Crítico');
    expect(
      (fixture.nativeElement.querySelector('.bento-epi-list') as HTMLElement).textContent,
    ).not.toContain('Botina de Segurança');

    // Entregas: 3 unidades nos últimos 6 meses e os dois termos mais recentes
    expect(tela).toContain('3 unidade(s) nos últimos 6 meses');
    expect(tela).toContain('Ana Ribeiro');
    expect(tela).toContain(comoDataBr(ENTREGA_RECENTE));
    expect(tela).toContain('Assinado');
    expect(tela).toContain('Sem assinatura');

    // Atividade recente vem da trilha de auditoria
    expect(tela).toContain('Entrega de EPI registrada.');
    expect(tela).toContain(comoDataHoraBr(LOG));
  });

  it('mostra o erro da API e volta a carregar quando o usuario pede', () => {
    const fixture = montar();

    // Uma falha em qualquer fonte derruba a carga inteira: as outras ficam canceladas pelo forkJoin.
    http
      .expectOne(FONTES[0].url)
      .flush(
        { mensagem: 'Banco indisponível.' },
        { status: 503, statusText: 'Service Unavailable' },
      );
    fixture.detectChanges();

    expect(fixture.nativeElement.textContent).toContain('Banco indisponível.');

    const botao = fixture.nativeElement.querySelector(
      '[data-acao="recarregar"]',
    ) as HTMLButtonElement;
    botao.click();
    responderTudo();
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
      responderTudo();
      fixture.detectChanges();

      const botao = fixture.nativeElement.querySelector(
        '[data-acao="exportar"]',
      ) as HTMLButtonElement;
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
