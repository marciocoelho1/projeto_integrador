import { HttpClient, provideHttpClient, withInterceptors } from '@angular/common/http';
import { provideHttpClientTesting, HttpTestingController } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { catchError, firstValueFrom, of } from 'rxjs';
import { demoApiInterceptor, reiniciarDemo } from './demo-api.interceptor';
import { calcularIndicadores, criarEstadoDemo } from './demo-dados';

const API = 'http://localhost:8080/api';

describe('Modo demonstração (API em memória)', () => {
  let http: HttpTestingController;
  let client: HttpClient;

  beforeEach(async () => {
    reiniciarDemo();

    await TestBed.configureTestingModule({
      providers: [
        provideHttpClient(withInterceptors([demoApiInterceptor])),
        provideHttpClientTesting(),
      ],
    }).compileComponents();

    http = TestBed.inject(HttpTestingController);
    client = TestBed.inject(HttpClient);
  });

  afterEach(() => {
    // Nada da API pode chegar ao backend de testes: o interceptor responde tudo em memória.
    http.verify();
  });

  it('autentica as contas de demonstração e recusa senha errada', async () => {
    const login = await firstValueFrom(
      client.post<{ token: string; usuario: { grupo: string; modulos: string[] } }>(
        `${API}/auth/login`,
        {
          login: 'admin',
          senha: '123456',
        },
      ),
    );

    expect(login.token).toContain('demo-admin');
    expect(login.usuario.grupo).toBe('Administrador TST');
    expect(login.usuario.modulos).toContain('sgst_dashboard');

    const status = await firstValueFrom(
      client
        .post(`${API}/auth/login`, { login: 'admin', senha: 'errada' })
        .pipe(catchError((falha) => of(falha.status))),
    );

    expect(status).toBe(401);
  });

  it('devolve as listas e os indicadores do estado de exemplo', async () => {
    const colaboradores = await firstValueFrom(
      client.get<Array<{ nome: string; setor: string }>>(`${API}/colaboradores`),
    );

    expect(colaboradores.length).toBe(16);
    expect(colaboradores.map((item) => item.setor)).toContain('Açougue');

    const indicadores = await firstValueFrom(
      client.get<{ colaboradores: { total: number; ativos: number }; alertas: unknown[] }>(
        `${API}/dashboard/indicadores`,
      ),
    );

    expect(indicadores.colaboradores.total).toBe(16);
    expect(indicadores.colaboradores.ativos).toBe(12);
    expect(indicadores.alertas.length).toBeGreaterThan(0);
  });

  it('permite incluir e excluir registros durante a sessão', async () => {
    const url = `${API}/epis`;

    const criado = await firstValueFrom(
      client.post<{ id: number }>(url, {
        descricao: 'Luva de Vaqueta',
        ca: '55555',
        quantidade: 10,
        inclusao: '2026-01-10',
        validade: '2027-01-10',
      }),
    );

    expect(criado.id).toBeGreaterThan(0);
    expect((await firstValueFrom(client.get<unknown[]>(url))).length).toBe(9);

    await firstValueFrom(client.delete<void>(`${url}/${criado.id}`));

    expect((await firstValueFrom(client.get<unknown[]>(url))).length).toBe(8);
  });

  it('entrega os relatórios em CSV como Blob', async () => {
    const arquivo = await firstValueFrom(
      client.get(`${API}/relatorios/colaboradores.csv`, { responseType: 'blob' }),
    );

    expect(arquivo).toBeInstanceOf(Blob);
    expect(await arquivo.text()).toContain('Matrícula;Nome;CPF');
  });

  it('deixa passar as requisições que não são da API', () => {
    client.get('/logo_projeto.png').subscribe();

    // Sem o interceptor respondendo, a requisição chega ao backend de testes.
    http.expectOne('/logo_projeto.png').flush('imagem');
  });

  it('importa planilhas e devolve o resumo por linha', async () => {
    const antes = await firstValueFrom(client.get<unknown[]>(`${API}/colaboradores`));

    const resumo = await firstValueFrom(
      client.post<{
        total: number;
        importados: number;
        ignorados: number;
        erros: Array<{ linha: number }>;
      }>(`${API}/importacao/colaboradores`, {
        linhas: [
          { matricula: '900', nome: 'Novo Colaborador', setor: 'Padaria' },
          { matricula: '', nome: 'Sem matrícula' },
          { matricula: '001', nome: 'Já existe' },
        ],
      }),
    );

    expect(resumo).toEqual({
      total: 3,
      importados: 1,
      ignorados: 1,
      erros: [{ linha: 3, mensagem: 'Campos obrigatórios ausentes: matricula.' }],
    });

    const depois = await firstValueFrom(client.get<unknown[]>(`${API}/colaboradores`));
    expect(depois.length).toBe(antes.length + 1);
  });

  it('avisa no console quando alguma rota da API não existe no modo demonstração', async () => {
    const status = await firstValueFrom(
      client.get(`${API}/rota-inexistente`).pipe(catchError((falha) => of(falha.status))),
    );

    expect(status).toBe(404);
  });
});

describe('Dados do modo demonstração', () => {
  it('calcula os mesmos indicadores que o backend calcula no banco', () => {
    const indicadores = calcularIndicadores(criarEstadoDemo());

    expect(indicadores.colaboradores).toEqual({ total: 16, ativos: 12, inativos: 3, afastados: 1 });
    expect(indicadores.treinamentos.total).toBe(24);
    expect(indicadores.epis.totalTipos).toBe(8);
    expect(indicadores.alertas.map((alerta) => alerta.tipo)).toContain('EPI');
    expect(indicadores.geradoEm).toBeTruthy();
  });
});
