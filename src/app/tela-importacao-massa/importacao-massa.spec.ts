import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting, HttpTestingController } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { ImportacaoMassa } from './importacao-massa';

const RECURSO: Record<string, string> = {
  colaborador: 'colaboradores',
  treinamento: 'treinamentos',
  epi: 'epis',
};

describe('ImportacaoMassa - mapeamento do contrato', () => {
  let componente: ImportacaoMassa;
  let http: HttpTestingController;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ImportacaoMassa],
      providers: [provideHttpClient(), provideHttpClientTesting()],
    }).compileComponents();
    componente = TestBed.createComponent(ImportacaoMassa).componentInstance;
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    // A tela registra auditoria (POST /api/auditoria) depois de cada importacao bem-sucedida.
    // Ha um teste dedicado para esse contrato; aqui as requisicoes de auditoria sao apenas
    // consumidas para que o verify() abaixo nao acuse pendencia em todos os casos.
    http
      .match((requisicao) => requisicao.url === 'http://localhost:8080/api/auditoria')
      .forEach((requisicao) =>
        requisicao.flush({
          id: 1,
          dataHora: '2026-01-01T00:00:00',
          usuarioId: 1,
          usuario: 'Marcio Coelho',
          modulo: 'Importação',
          acao: 'CRIACAO',
          descricao: 'Importou registros via planilha Excel/CSV',
          metodo: 'POST',
          caminho: '/api/auditoria',
          statusHttp: 201,
        }),
      );
    http.verify();
  });

  function carregar(tipo: string, cabecalhos: string[], linhas: string[][]) {
    componente.tipoImportacao.set(tipo);
    componente.cabecalhos.set(cabecalhos);
    componente.linhasPreview.set(linhas);
    componente.confirmarImportacao();
  }

  it('mapeia colaborador pelos cabecalhos e envia o contrato', () => {
    carregar(
      'colaborador',
      ['Matrícula', 'Nome', 'CPF', 'E-mail', 'Cargo', 'Setor', 'Status'],
      [['MAT-001', ' João da Silva ', '111.222.333-44', 'JOAO@Empresa.com', 'Operador', 'Loja', 'Ativo']],
    );

    const req = http.expectOne('http://localhost:8080/api/importacao/colaboradores');
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual({
      linhas: [
        {
          matricula: 'MAT-001',
          nome: 'João da Silva',
          cpf: '111.222.333-44',
          email: 'JOAO@Empresa.com',
          cargo: 'Operador',
          setor: 'Loja',
          status: 'Ativo',
        },
      ],
    });
    req.flush({ total: 1, importados: 1, ignorados: 0, erros: [] });
    expect(componente.resultadoImportados()).toBe(1);
  });

  it('aceita os nomes antigos dos modelos de treinamento e ignora Obrigatorio', () => {
    carregar(
      'treinamento',
      [
        'Codigo',
        'Nome_Treinamento',
        'Classificacao',
        'NR_Referente',
        'Carga_Horária',
        'Validade_Meses',
        'Status',
        'Obrigatorio',
      ],
      [['T01', 'NR-35 Trabalho em Altura', 'Norma', 'NR-35', '8', '24', 'Ativo', 'Sim']],
    );

    const req = http.expectOne('http://localhost:8080/api/importacao/treinamentos');
    const linha: any = (req.request.body as any).linhas[0];
    expect(linha.nome).toBe('NR-35 Trabalho em Altura');
    expect(linha.cargaHoraria).toBe('8');
    expect(linha.validadeMeses).toBe(24);
    expect(linha.nr).toBe('NR-35');
    expect(linha.obrigatorio).toBeUndefined();
    req.flush({ total: 1, importados: 1, ignorados: 0, erros: [] });
  });

  it('reporta a linha quando o modelo antigo nao tem as colunas obrigatorias', () => {
    carregar(
      'treinamento',
      ['Nome_Treinamento', 'Carga_Horaria', 'Validade_Meses', 'NR_Referente', 'Obrigatorio'],
      [['NR-35 Trabalho em Altura', '8', '24', 'NR-35', 'Sim']],
    );

    http.expectNone('http://localhost:8080/api/importacao/treinamentos');
    expect(componente.erros().length).toBe(1);
    expect(componente.erros()[0].linha).toBe(2);
    expect(componente.erros()[0].mensagem).toContain('codigo');
    expect(componente.erros()[0].mensagem).toContain('classificacao');
    expect(componente.erros()[0].mensagem).toContain('status');
    expect(componente.resultadoImportados()).toBe(0);
  });

  it('mapeia EPI convertendo datas para ISO e descartando colunas inexistentes', () => {
    carregar(
      'epi',
      ['Nome_Equipamento', 'Numero_CA', 'Fabricante', 'Validade_Dias', 'Setor_Risco'],
      [['Capacete', '12345', 'Delta', '365', 'Estoque']],
    );

    // Sem colunas de inclusao/validade reconheciveis a linha nao e enviada.
    expect(componente.erros().length).toBe(1);
    expect(componente.erros()[0].linha).toBe(2);
    http.expectNone('http://localhost:8080/api/importacao/epis');

    carregar(
      'epi',
      ['Descricao', 'CA', 'Inclusao', 'Validade', 'Quantidade'],
      [['Capacete', '12345', '01/02/2026', '2027-02-01', '10']],
    );

    const req = http.expectOne('http://localhost:8080/api/importacao/epis');
    expect(req.request.body).toEqual({
      linhas: [
        {
          descricao: 'Capacete',
          ca: '12345',
          inclusao: '2026-02-01',
          validade: '2027-02-01',
          quantidade: 10,
        },
      ],
    });
    req.flush({ total: 1, importados: 1, ignorados: 0, erros: [] });
  });

  it('converte numero de serie do Excel em data ISO', () => {
    carregar(
      'epi',
      ['Descricao', 'CA', 'Inclusao', 'Validade', 'Quantidade'],
      [['Luva', '99', '46023', '46388', '2']],
    );

    const req = http.expectOne('http://localhost:8080/api/importacao/epis');
    const linha: any = (req.request.body as any).linhas[0];
    expect(linha.inclusao).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    expect(linha.validade).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    req.flush({ total: 1, importados: 1, ignorados: 0, erros: [] });
  });

  it('rejeita valores nao numericos na quantidade sem enviar a linha', () => {
    carregar(
      'epi',
      ['Descricao', 'CA', 'Inclusao', 'Validade', 'Quantidade'],
      [['Luva', '99', '2026-01-01', '2027-01-01', 'muitas']],
    );

    http.expectNone('http://localhost:8080/api/importacao/epis');
    expect(componente.erros()[0].mensagem).toContain('Quantidade');
  });

  it('combina erros de mapeamento com os erros devolvidos pela API', () => {
    componente.tipoImportacao.set('colaborador');
    componente.cabecalhos.set(['Matricula', 'Nome', 'CPF', 'Email', 'Cargo', 'Setor', 'Status']);
    componente.linhasPreview.set([
      ['MAT-001', 'Ana', '11122233344', 'a@b.com', 'Cargo', 'Setor', 'Ativo'],
      ['MAT-002', 'Bia', '22233344455', 'b@b.com', 'Cargo', 'Setor', 'Ativo'],
    ]);
    componente.confirmarImportacao();

    http
      .expectOne('http://localhost:8080/api/importacao/colaboradores')
      .flush({
        total: 2,
        importados: 1,
        ignorados: 1,
        erros: [{ linha: 3, mensagem: 'Já existe um colaborador com este CPF.' }],
      });

    expect(componente.resultadoImportados()).toBe(1);
    expect(componente.erros()).toEqual([
      { linha: 3, mensagem: 'Já existe um colaborador com este CPF.' },
    ]);
  });

  it('nao envia nada quando nenhuma linha e mapeavel', () => {
    carregar('colaborador', ['Foo', 'Bar'], [['a', 'b']]);

    http.expectNone('http://localhost:8080/api/importacao/colaboradores');
    expect(componente.resultadoImportados()).toBe(0);
    expect(componente.erros().length).toBe(1);
  });

  it('registra auditoria depois de importar com sucesso', () => {
    carregar(
      'colaborador',
      ['Matrícula', 'Nome', 'CPF', 'E-mail', 'Cargo', 'Setor', 'Status'],
      [['MAT-009', 'Rita Souza', '99988877766', 'rita@empresa.com', 'Operador', 'Loja', 'Ativo']],
    );

    http
      .expectOne('http://localhost:8080/api/importacao/colaboradores')
      .flush({ total: 1, importados: 1, ignorados: 0, erros: [] });

    const auditoria = http.expectOne('http://localhost:8080/api/auditoria');
    expect(auditoria.request.method).toBe('POST');
    expect(auditoria.request.body).toEqual({
      usuario: 'Marcio Coelho',
      modulo: 'Importação',
      acao: 'CRIACAO',
      descricao: 'Importou 1 registro(s) via planilha Excel/CSV',
    });
    auditoria.flush({
      id: 7,
      dataHora: '2026-01-01T00:00:00',
      usuarioId: null,
      usuario: 'Marcio Coelho',
      modulo: 'Importação',
      acao: 'CRIACAO',
      descricao: 'Importou 1 registro(s) via planilha Excel/CSV',
      metodo: 'POST',
      caminho: '/api/auditoria',
      statusHttp: 201,
    });
  });

  it('os modelos CSV baixados tem exatamente as colunas do contrato', () => {
    const conteudos: string[] = [];
    const blobOriginal = globalThis.Blob;
    const criarUrlOriginal = URL.createObjectURL;
    const clicarOriginal = HTMLAnchorElement.prototype.click;

    (globalThis as any).Blob = class {
      constructor(partes: unknown[]) {
        conteudos.push(partes.join(''));
      }
    };
    (URL as any).createObjectURL = () => 'blob:teste';
    HTMLAnchorElement.prototype.click = () => {};

    try {
      (['colaborador', 'treinamento', 'epi'] as const).forEach((tipo) => {
        componente.tipoImportacao.set(tipo);
        componente.baixarTemplate();
      });
    } finally {
      (globalThis as any).Blob = blobOriginal;
      (URL as any).createObjectURL = criarUrlOriginal;
      HTMLAnchorElement.prototype.click = clicarOriginal;
    }

    expect(conteudos.length).toBe(3);

    (['colaborador', 'treinamento', 'epi'] as const).forEach((tipo, indice) => {
      const [cabecalho, dado] = conteudos[indice]
        .trim()
        .split('\n')
        .map((linha) => linha.split(','));

      carregar(tipo, cabecalho, [dado]);

      const req = http.expectOne(`http://localhost:8080/api/importacao/${RECURSO[tipo]}`);
      const linha = (req.request.body as any).linhas[0];

      Object.entries(linha).forEach(([campo, valor]) => {
        if (campo === 'nr' || campo === 'validadeMeses') return;
        expect(`${campo}=${String(valor)}`).not.toBe(`${campo}=`);
        expect(valor).not.toBeNull();
      });

      req.flush({ total: 1, importados: 1, ignorados: 0, erros: [] });
    });
  });
});
