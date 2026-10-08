import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { Epis } from './epis';

describe('Epis', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Epis],
      providers: [provideRouter([])],
    }).compileComponents();
  });

  it('fecha o modal de entrega apenas ao clicar no overlay', () => {
    const fixture = TestBed.createComponent(Epis);
    const component = fixture.componentInstance;

    component.abrirModalEntrega();
    fixture.detectChanges();

    const overlay = fixture.nativeElement.querySelector('.sst-modal-overlay') as HTMLElement;
    const modal = overlay.querySelector('.sst-modal') as HTMLElement;

    modal.click();
    expect(component.mostrarModalEntrega).toBe(true);

    overlay.click();
    expect(component.mostrarModalEntrega).toBe(false);
  });
});
