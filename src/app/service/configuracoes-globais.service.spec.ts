import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting, HttpTestingController } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { ConfiguracoesGlobaisService } from './configuracoes-globais.service';

describe('ConfiguracoesGlobaisService', () => {
  let http: HttpTestingController;
  let service: ConfiguracoesGlobaisService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    http = TestBed.inject(HttpTestingController);
    service = TestBed.inject(ConfiguracoesGlobaisService);
  });

  afterEach(() => http.verify());

  it('carrega regras e parametros da API', () => {
    service.carregar();

    http.expectOne('http://localhost:8080/api/regras-alerta').flush([
      { codigo: 'estoqueEpi', nomeRegra: 'Ruptura de Estoque (EPI)', descricaoRegra: 'Estoque mínimo.', ativa: true },
      { codigo: 'treinamentoVencido', nomeRegra: 'Reciclagem de NRs', descricaoRegra: 'Vencimento de NRs.', ativa: false },
    ]);
    http.expectOne('http://localhost:8080/api/parametros').flush([
      { chave: 'estoqueMinimoEpi', valor: '5', descricao: 'Quantidade mínima em estoque.' },
      { chave: 'diasAvisoReciclagem', valor: '60', descricao: 'Antecedência do aviso.' },
    ]);

    expect(service.regras().length).toBe(2);
    expect(service.regras()[0].isAtiva).toBe(true);
    expect(service.regras()[1].isAtiva).toBe(false);
    expect(service.parametros().length).toBe(2);
    expect(service.parametros()[0].chave).toBe('estoqueMinimoEpi');
    expect(service.erro()).toBeNull();
    expect(service.carregando()).toBe(false);
  });

  it('registra o erro da API sem quebrar a tela', () => {
    service.carregar();

    const regras = http.expectOne('http://localhost:8080/api/regras-alerta');
    const parametros = http.expectOne('http://localhost:8080/api/parametros');

    regras.flush({ mensagem: 'Sessão expirada.' }, { status: 401, statusText: 'Unauthorized' });

    expect(service.erro()).toBe('Sessão expirada.');
    expect(service.carregando()).toBe(false);

    // O forkJoin cancela a outra requisição quando a primeira falha; se ainda estiver aberta, é
    // consumida aqui para o verify() do fim não acusar pendência.
    if (!parametros.cancelled) {
      parametros.flush([]);
    }
  });

  it('liga a regra no servidor e no estado da tela', () => {
    service.regras.set([
      { codigo: 'treinamentoVencido', nomeRegra: 'Reciclagem de NRs', descricaoRegra: 'x', isAtiva: false },
    ]);

    service.definirAtiva('treinamentoVencido', true).subscribe();

    const requisicao = http.expectOne('http://localhost:8080/api/regras-alerta/treinamentoVencido');
    expect(requisicao.request.method).toBe('PUT');
    expect(requisicao.request.body).toEqual({ ativa: true });
    requisicao.flush({
      codigo: 'treinamentoVencido',
      nomeRegra: 'Reciclagem de NRs',
      descricaoRegra: 'x',
      ativa: true,
    });

    expect(service.regras()[0].isAtiva).toBe(true);
  });

  it('grava os parametros alterados e mantem o valor devolvido', () => {
    service.parametros.set([
      { chave: 'estoqueMinimoEpi', valor: '5', descricao: 'Estoque mínimo.' },
      { chave: 'diasAvisoReciclagem', valor: '60', descricao: 'Antecedência.' },
    ]);

    service
      .salvarValores([
        { chave: 'estoqueMinimoEpi', valor: '8' },
        { chave: 'diasAvisoReciclagem', valor: '90' },
      ])
      .subscribe();

    expect(service.salvando()).toBe(true);

    http
      .expectOne('http://localhost:8080/api/parametros/estoqueMinimoEpi')
      .flush({ chave: 'estoqueMinimoEpi', valor: '8', descricao: 'Estoque mínimo.' });
    http
      .expectOne('http://localhost:8080/api/parametros/diasAvisoReciclagem')
      .flush({ chave: 'diasAvisoReciclagem', valor: '90', descricao: 'Antecedência.' });

    expect(service.parametros().map((parametro) => parametro.valor)).toEqual(['8', '90']);
    expect(service.salvando()).toBe(false);
  });
});
