import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { DadosReferenciaService } from '../service/dados-referencia.service';
import { ToastService } from '../service/toast.service';
import { Cadastramentos } from './cadastramentos';

describe('Cadastramentos', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Cadastramentos],
      providers: [provideRouter([]), provideHttpClient(), provideHttpClientTesting()],
    }).compileComponents();
  });

  it('possui campos do contrato e sinaliza acesso fora do escopo', () => {
    const fixture = TestBed.createComponent(Cadastramentos);
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('#matricula')).toBeTruthy();
    expect(fixture.nativeElement.querySelector('#status-colaborador')).toBeTruthy();
    expect(fixture.nativeElement.querySelector('#grupo-acesso')).toBeNull();
    expect(fixture.nativeElement.textContent).toContain('não estão integrados');
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
      matricula: '001',
      status: 'Ativo',
    };
    fixture.detectChanges();
    await fixture.whenStable();

    const formulario = fixture.nativeElement.querySelector('form') as HTMLFormElement;
    formulario.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
    fixture.detectChanges();

    expect(toast.toasts().at(-1)?.tipo).toBe('erro');
  });
});
