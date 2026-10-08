import { TestBed } from '@angular/core/testing';
import { provideHttpClient, HttpErrorResponse } from '@angular/common/http';
import { provideHttpClientTesting, HttpTestingController } from '@angular/common/http/testing';
import { EpisService } from './epis.service';
import { ColaboradorService } from './colaborador.service';
import { TreinamentoService } from './treinamento.service';
const colaborador = {
  matricula: '001',
  nome: 'Pessoa',
  cpf: '12345678900',
  email: 'p@a.com',
  cargo: 'Cargo',
  setor: 'Setor',
  status: 'Ativo' as const,
};
const treinamento = {
  codigo: 'T1',
  nome: 'Curso',
  classificacao: 'Geral',
  nr: null,
  cargaHoraria: '4h',
  validadeMeses: null,
  status: 'Ativo' as const,
};
const epi = {
  descricao: 'Luva',
  ca: '00123',
  inclusao: '2026-10-08',
  validade: '2027-10-08',
  quantidade: 2,
};
describe('Contratos CRUD HTTP', () => {
  beforeEach(() =>
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    }),
  );
  afterEach(() => TestBed.inject(HttpTestingController).verify());
  for (const recurso of ['colaboradores', 'treinamentos', 'epis']) {
    it(`executa GET lista/id POST PUT DELETE ${recurso} com IDs numéricos e payload exato`, () => {
      const http = TestBed.inject(HttpTestingController);
      const s: any =
        recurso === 'epis'
          ? TestBed.inject(EpisService)
          : recurso === 'treinamentos'
            ? TestBed.inject(TreinamentoService)
            : TestBed.inject(ColaboradorService);
      const data =
        recurso === 'epis' ? epi : recurso === 'treinamentos' ? treinamento : colaborador;
      const url = `http://localhost:8080/api/${recurso}`;
      const methods =
        recurso === 'epis'
          ? ['obterEpis', 'obterEpiPorId', 'cadastrarEpi', 'atualizarEpi', 'excluirEpi']
          : ['listar', 'buscarPorId', 'criar', 'atualizar', 'excluir'];
      s[methods[0]]().subscribe((r: any) => expect(r).toEqual([{ id: 7, ...data }]));
      http.expectOne(url).flush([{ id: 7, ...data }]);
      s[methods[1]](7).subscribe();
      const get = http.expectOne(url + '/7');
      expect(get.request.method).toBe('GET');
      get.flush({ id: 7, ...data });
      s[methods[2]](data).subscribe();
      const post = http.expectOne(url);
      expect(post.request.method).toBe('POST');
      expect(post.request.body).toEqual(data);
      post.flush({ id: 7, ...data });
      s[methods[3]](7, data).subscribe();
      const put = http.expectOne(url + '/7');
      expect(put.request.method).toBe('PUT');
      expect(put.request.body).toEqual(data);
      put.flush({ id: 7, ...data });
      s[methods[4]](7).subscribe();
      const del = http.expectOne(url + '/7');
      expect(del.request.method).toBe('DELETE');
      del.flush(null);
    });
  }
  it('propaga falha da API sem transformar erro em sucesso', () => {
    let erro: HttpErrorResponse | undefined;
    TestBed.inject(ColaboradorService)
      .criar(colaborador)
      .subscribe({ error: (e) => (erro = e) });
    TestBed.inject(HttpTestingController)
      .expectOne('http://localhost:8080/api/colaboradores')
      .flush({ mensagem: 'Duplicado' }, { status: 409, statusText: 'Conflict' });
    expect(erro?.status).toBe(409);
  });
});
