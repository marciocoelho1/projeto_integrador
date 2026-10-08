import { TestBed } from '@angular/core/testing';
import { AreaColaborador } from './area-colaborador';

describe('AreaColaborador', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AreaColaborador],
    }).compileComponents();
  });

  it('exibe os dados completos dos EPIs com identificadores únicos e quantidades positivas', () => {
    const fixture = TestBed.createComponent(AreaColaborador);
    fixture.detectChanges();

    const tables = fixture.nativeElement.querySelectorAll('table') as NodeListOf<HTMLTableElement>;
    const epiTable = tables.item(tables.length - 1);
    const headers = Array.from(epiTable.querySelectorAll('th')).map((header) =>
      header.textContent?.trim(),
    );
    const ids = fixture.componentInstance.meusEpis.map((epi) => epi.id);

    expect(headers).toEqual([
      'ID',
      'EPI',
      'Quantidade',
      'CA',
      'Data de Entrega',
      'Assinatura do Termo',
    ]);
    expect(new Set(ids).size).toBe(ids.length);
    expect(fixture.componentInstance.meusEpis.every((epi) => epi.quantidade > 0)).toBe(true);
    expect(epiTable.textContent).toContain('EPI-001');
    expect(epiTable.textContent).toContain('18.103');
  });

  it('faz o estado vazio ocupar as seis colunas da tabela de EPIs', () => {
    const fixture = TestBed.createComponent(AreaColaborador);
    fixture.componentInstance.meusEpis = [];
    fixture.detectChanges();

    const emptyCell = fixture.nativeElement.querySelector(
      'main > section.sst-card tbody td',
    ) as HTMLTableCellElement;

    expect(emptyCell.colSpan).toBe(6);
    expect(emptyCell.textContent).toContain('Nenhum EPI registrado');
  });

  it('apresenta o prazo como alerta acessível e preserva o link do material', () => {
    const fixture = TestBed.createComponent(AreaColaborador);
    fixture.detectChanges();

    const deadline = fixture.nativeElement.querySelector(
      '.area-colaborador__deadline',
    ) as HTMLElement;
    const icon = deadline.querySelector('svg') as SVGElement;
    const link = fixture.nativeElement.querySelector(
      '.area-colaborador__material .sst-btn-link',
    ) as HTMLAnchorElement;
    const detailsGrid = fixture.nativeElement.querySelector(
      '.area-colaborador__details-grid',
    ) as HTMLElement;

    expect(deadline.getAttribute('role')).toBe('status');
    expect(deadline.getAttribute('aria-label')).toContain('Alerta: Prazo de conclusão:');
    expect(icon.getAttribute('aria-hidden')).toBe('true');
    expect(link.target).toBe('_blank');
    expect(link.rel).toBe('noopener noreferrer');
    expect(detailsGrid.querySelectorAll(':scope > .sst-card')).toHaveLength(2);
  });
});
