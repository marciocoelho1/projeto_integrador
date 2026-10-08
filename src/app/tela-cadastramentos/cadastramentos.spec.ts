import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { DadosReferenciaService } from '../service/dados-referencia.service';
import { ToastService } from '../service/toast.service';
import { Cadastramentos } from './cadastramentos';

describe('Cadastramentos', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Cadastramentos],
      providers: [provideRouter([])],
    }).compileComponents();
  });

  it('carrega cargos, setores e grupos da fonte compartilhada', () => {
    const fixture = TestBed.createComponent(Cadastramentos);
    const dadosReferencia = TestBed.inject(DadosReferenciaService);
    fixture.detectChanges();

    const opcoes = (seletor: string) =>
      Array.from(
        fixture.nativeElement.querySelectorAll(
          `${seletor} option:not([value=''])`,
        ) as NodeListOf<HTMLOptionElement>,
      ).map((opcao) => ({ valor: opcao.value, texto: opcao.textContent?.trim() }));

    expect(opcoes('#cargo').map((opcao) => opcao.valor)).toEqual(dadosReferencia.cargosCadastrados);
    expect(opcoes('#setor').map((opcao) => opcao.valor)).toEqual(
      dadosReferencia.setoresCadastrados,
    );
    expect(opcoes('#grupo-acesso')).toEqual(
      dadosReferencia.gruposAcesso().map((grupo) => ({
        valor: grupo.id,
        texto: grupo.nomenclatura,
      })),
    );
  });

  it('impede o cadastro quando o e-mail é inválido', async () => {
    const fixture = TestBed.createComponent(Cadastramentos);
    const component = fixture.componentInstance;
    const toast = TestBed.inject(ToastService);

    component.novoColaborador = {
      nome: 'Pessoa Teste',
      cpf: '123.456.789-00',
      email: 'email-invalido',
      cargo: component.cargosCadastrados[0],
      setor: component.setoresCadastrados[0],
      grupoAcessoId: component.gruposAcesso()[0].id,
    };
    fixture.detectChanges();
    await fixture.whenStable();

    const formulario = fixture.nativeElement.querySelector('form') as HTMLFormElement;
    formulario.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
    fixture.detectChanges();

    expect(toast.toasts().at(-1)?.tipo).toBe('erro');
  });
});
