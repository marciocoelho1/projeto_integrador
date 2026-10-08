import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { ToastService } from '../service/toast.service';
import { Colaboradores } from './colaboradores';

describe('Colaboradores', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Colaboradores],
      providers: [provideRouter([])],
    }).compileComponents();
  });

  it('fecha o modal de detalhes apenas ao clicar no overlay', () => {
    const fixture = TestBed.createComponent(Colaboradores);
    const component = fixture.componentInstance;

    component.abrirModalDetalhes(component.colaboradores[0]);
    fixture.detectChanges();

    const overlay = fixture.nativeElement.querySelector('.sst-modal-overlay') as HTMLElement;
    const modal = overlay.querySelector('.sst-modal') as HTMLElement;

    modal.click();
    expect(component.mostrarModalDetalhes).toBe(true);

    overlay.click();
    expect(component.mostrarModalDetalhes).toBe(false);
  });

  it('exibe e-mail válido para todos os colaboradores', () => {
    const fixture = TestBed.createComponent(Colaboradores);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    const cabecalhos = Array.from(
      fixture.nativeElement.querySelectorAll('thead th') as NodeListOf<HTMLElement>,
    ).map((elemento) => elemento.textContent?.trim());

    expect(cabecalhos).toContain('E-mail');
    expect(
      component.colaboradores.every((colaborador) =>
        /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(colaborador.email),
      ),
    ).toBe(true);
  });

  it('mantém o modal aberto quando o e-mail editado é inválido', async () => {
    const fixture = TestBed.createComponent(Colaboradores);
    const component = fixture.componentInstance;
    const toast = TestBed.inject(ToastService);

    component.abrirModalDetalhes(component.colaboradores[0]);
    fixture.detectChanges();
    component.colaboradorEmEdicao!.email = 'email-invalido';
    fixture.detectChanges();
    await fixture.whenStable();

    const formulario = fixture.nativeElement.querySelector('form') as HTMLFormElement;
    formulario.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
    fixture.detectChanges();

    expect(component.mostrarModalDetalhes).toBe(true);
    expect(toast.toasts().at(-1)?.tipo).toBe('erro');
  });
});
