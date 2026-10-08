import { vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { provideRouter } from '@angular/router';
import { NgForm } from '@angular/forms';
import { Colaboradores } from './tela-colaboradores/colaboradores';
import { Epis } from './tela-epis/epis';
import { MatrizTreinamentos } from './tela-matriz-treinamento/matriz-treinamento';
import { Cadastramentos } from './tela-cadastramentos/cadastramentos';
import { ToastService } from './service/toast.service';
const colab = {
  id: 7,
  matricula: '001',
  nome: 'Teste',
  cpf: '12345678900',
  email: 'a@b.com',
  cargo: 'Cargo',
  setor: 'Setor',
  status: 'Ativo' as const,
};
const epi = {
  id: 7,
  descricao: 'Luva nova',
  ca: '0001',
  quantidade: 2,
  inclusao: '2026-10-08',
  validade: '2027-10-08',
};
const treino = {
  id: 7,
  codigo: 'T1',
  nome: 'Curso novo',
  classificacao: 'Geral',
  nr: null,
  cargaHoraria: '4h',
  validadeMeses: null,
  status: 'Ativo' as const,
};
const form = {
  invalid: false,
  control: { markAllAsTouched() {} },
  controls: {},
  resetForm() {},
} as unknown as NgForm;
describe('Telas CRUD reais', () => {
  beforeEach(() =>
    TestBed.configureTestingModule({
      providers: [provideRouter([]), provideHttpClient(), provideHttpClientTesting()],
    }),
  );
  afterEach(() => TestBed.inject(HttpTestingController).verify());
  for (const [component, resource, field, row] of [
    [Colaboradores, 'colaboradores', 'colaboradores', colab],
    [Epis, 'epis', 'epis', epi],
    [MatrizTreinamentos, 'treinamentos', 'treinamentos', treino],
  ] as const) {
    it(`carrega ${resource} sem exemplos e mantém erro visível`, () => {
      const fixture = TestBed.createComponent(component as any);
      const c: any = fixture.componentInstance;
      expect(c[field]).toEqual([]);
      fixture.detectChanges();
      const req = TestBed.inject(HttpTestingController).expectOne(
        `http://localhost:8080/api/${resource}`,
      );
      req.flush([row]);
      fixture.detectChanges();
      expect(c[field]).toEqual([row]);
      c.carregar();
      TestBed.inject(HttpTestingController)
        .expectOne(`http://localhost:8080/api/${resource}`)
        .error(new ProgressEvent('error'));
      expect(c.erro).toContain('API');
      expect(c[field]).toEqual([row]);
    });
  }
  it('edita colaborador via PUT e só fecha após confirmação; preserva edição no erro', () => {
    const c = TestBed.createComponent(Colaboradores).componentInstance;
    const http = TestBed.inject(HttpTestingController);
    c.colaboradores = [colab];
    c.abrirModalDetalhes(colab);
    http.expectOne('http://localhost:8080/api/colaboradores/7').flush(colab);
    c.colaboradorEmEdicao!.nome = 'Atualizado';
    c.salvarEdicaoDetalhes(form);
    expect(c.mostrarModalDetalhes).toBe(true);
    expect(c.colaboradores[0].nome).toBe('Teste');
    http
      .expectOne('http://localhost:8080/api/colaboradores/7')
      .flush({ mensagem: 'Duplicado' }, { status: 409, statusText: 'Conflict' });
    expect(c.mostrarModalDetalhes).toBe(true);
    expect(TestBed.inject(ToastService).toasts().at(-1)?.tipo).toBe('erro');
    c.salvarEdicaoDetalhes(form);
    http
      .expectOne('http://localhost:8080/api/colaboradores/7')
      .flush({ ...colab, nome: 'Atualizado' });
    expect(c.mostrarModalDetalhes).toBe(false);
    expect(c.colaboradores[0].nome).toBe('Atualizado');
  });
  it('cadastra colaborador com matrícula/status e sem grupo/senha; não anuncia sucesso antecipado', () => {
    const c: any = TestBed.createComponent(Cadastramentos).componentInstance;
    c.novoColaborador = { ...colab };
    delete c.novoColaborador.id;
    c.salvarColaborador(form);
    expect(TestBed.inject(ToastService).toasts().length).toBe(0);
    const req = TestBed.inject(HttpTestingController).expectOne(
      'http://localhost:8080/api/colaboradores',
    );
    expect(req.request.body).toEqual(c.novoColaborador);
    req.flush(colab);
    expect(TestBed.inject(ToastService).toasts().at(-1)?.tipo).toBe('sucesso');
  });
  it('cadastra treinamento mantendo carga textual e opcionais nulos', () => {
    const c: any = TestBed.createComponent(Cadastramentos).componentInstance;
    c.novoTreinamento = { ...treino };
    delete c.novoTreinamento.id;
    c.salvarTreinamento(form);
    const req = TestBed.inject(HttpTestingController).expectOne(
      'http://localhost:8080/api/treinamentos',
    );
    expect(req.request.body).toEqual(c.novoTreinamento);
    req.flush(treino);
  });
  it('cadastra EPI com datas ISO e CA textual', () => {
    const c: any = TestBed.createComponent(Cadastramentos).componentInstance;
    c.novoEpi = { ...epi };
    delete c.novoEpi.id;
    c.salvarEPI(form);
    const req = TestBed.inject(HttpTestingController).expectOne('http://localhost:8080/api/epis');
    expect(req.request.body).toEqual(c.novoEpi);
    req.flush(epi);
  });
  it('não abate estoque para entregas fora do escopo', () => {
    const c = TestBed.createComponent(Epis).componentInstance;
    (c as any).epis = [epi];
    c.abrirModalEntrega();
    c.salvarEntrega();
    expect(c.epis[0].quantidade).toBe(2);
    expect(c.entregas).toEqual([]);
    expect(TestBed.inject(ToastService).toasts().at(-1)?.tipo).not.toBe('sucesso');
  });
  for (const [component, resource, field, row] of [
    [Colaboradores, 'colaboradores', 'colaboradores', colab],
    [Epis, 'epis', 'epis', epi],
    [MatrizTreinamentos, 'treinamentos', 'treinamentos', treino],
  ] as const) {
    it(`exclui ${resource} por ID só após confirmar; mantém dados no erro`, () => {
      const c: any = TestBed.createComponent(component as any).componentInstance;
      c[field] = [row];
      const confirm = vi.spyOn(window, 'confirm').mockReturnValue(false);
      c.excluir(row);
      TestBed.inject(HttpTestingController).expectNone(`http://localhost:8080/api/${resource}/7`);
      confirm.mockReturnValue(true);
      c.excluir(row);
      expect(c[field]).toEqual([row]);
      const req = TestBed.inject(HttpTestingController).expectOne(
        `http://localhost:8080/api/${resource}/7`,
      );
      expect(req.request.method).toBe('DELETE');
      req.flush({ mensagem: 'Falha' }, { status: 500, statusText: 'Error' });
      expect(c[field]).toEqual([row]);
      c.excluir(row);
      TestBed.inject(HttpTestingController)
        .expectOne(`http://localhost:8080/api/${resource}/7`)
        .flush(null);
      expect(c[field]).toEqual([]);
      confirm.mockRestore();
    });
  }
  it('edita EPI sem restringir descrições ao catálogo fictício e mantém datas ISO', () => {
    const c = TestBed.createComponent(Epis).componentInstance;
    const http = TestBed.inject(HttpTestingController);
    c.epis = [epi];
    c.abrirModalEdicao(epi);
    http.expectOne('http://localhost:8080/api/epis/7').flush(epi);
    c.epiEmEdicao.descricao = 'Descrição livre';
    c.salvarEdicao(form);
    const req = http.expectOne('http://localhost:8080/api/epis/7');
    expect(req.request.method).toBe('PUT');
    expect(req.request.body.id).toBeUndefined();
    expect(req.request.body.inclusao).toBe('2026-10-08');
    req.flush({ ...epi, descricao: 'Descrição livre' });
    expect(c.epis[0].descricao).toBe('Descrição livre');
    expect(c.mostrarModalEdicao).toBe(false);
  });
  it('edita catálogo com nome livre, NR nula e status real', () => {
    const c = TestBed.createComponent(MatrizTreinamentos).componentInstance;
    const http = TestBed.inject(HttpTestingController);
    c.treinamentos = [treino];
    c.abrirModalEdicaoGeral(treino);
    http.expectOne('http://localhost:8080/api/treinamentos/7').flush(treino);
    c.itemEmEdicao.nome = 'Curso editado';
    c.salvarEdicaoGeral(form);
    const req = http.expectOne('http://localhost:8080/api/treinamentos/7');
    expect(req.request.method).toBe('PUT');
    expect(req.request.body.id).toBeUndefined();
    req.flush({ ...treino, nome: 'Curso editado' });
    expect(c.treinamentos[0].nome).toBe('Curso editado');
    expect(c.mostrarModalEdicaoGeral).toBe(false);
  });
  it('bloqueia fração de estoque antes do POST e mantém dados no erro de cadastro', () => {
    const c = TestBed.createComponent(Cadastramentos).componentInstance;
    const http = TestBed.inject(HttpTestingController);
    c.novoEpi = { ...epi, quantidade: 1.5 };
    c.salvarEPI(form);
    http.expectNone('http://localhost:8080/api/epis');
    c.novoEpi.quantidade = 2;
    c.salvarEPI(form);
    http
      .expectOne('http://localhost:8080/api/epis')
      .flush({ mensagem: 'Inválido' }, { status: 400, statusText: 'Bad Request' });
    expect(c.novoEpi.descricao).toBe(epi.descricao);
    expect(c.erro).toBe('Inválido');
    expect(c.salvandoEpi).toBe(false);
  });

  it('mostra exclusão no catálogo real e campos completos na edição de EPI', () => {
    const fixture = TestBed.createComponent(MatrizTreinamentos);
    fixture.detectChanges();
    TestBed.inject(HttpTestingController)
      .expectOne('http://localhost:8080/api/treinamentos')
      .flush([treino]);
    fixture.detectChanges();
    const actions = Array.from(
      fixture.nativeElement.querySelectorAll('tbody button') as NodeListOf<HTMLButtonElement>,
    );
    expect(actions.map((b) => b.textContent?.trim())).toContain('Excluir');
    const epiFixture = TestBed.createComponent(Epis);
    epiFixture.componentInstance.abrirModalEdicao(epi);
    TestBed.inject(HttpTestingController).expectOne('http://localhost:8080/api/epis/7').flush(epi);
    epiFixture.detectChanges();
    TestBed.inject(HttpTestingController).expectOne('http://localhost:8080/api/epis').flush([]);
    expect(epiFixture.nativeElement.querySelector('#inclusao-epi-edit')).toBeTruthy();
  });
});
