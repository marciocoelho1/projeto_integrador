import { validarEpi } from '../service/crud-validation';
import { ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';
import { Router } from '@angular/router';
import { ToastService } from '../service/toast.service';
import { EpisService, Epi } from '../service/epis.service';
import { finalize } from 'rxjs';
import { mensagemErroApi } from '../service/api-error';

interface EntregaEpi {
  colaborador: string;
  epi: string;
  quantidade?: number;
  data: string;
  validadeCa?: string;
  numeroCa?: string;
  assinatura: string;
}

@Component({
  selector: 'app-epis',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './epis.html',
  styleUrls: ['./epis.scss'],
})
export class Epis implements OnInit {
  private router = inject(Router);
  private toast = inject(ToastService);
  private api = inject(EpisService);
  private cdr = inject(ChangeDetectorRef);
  erro = '';
  carregando = false;
  salvando = false;
  ngOnInit() {
    this.carregar();
  }
  carregar() {
    if (this.carregando) return;
    this.carregando = true;
    this.erro = '';
    this.api
      .obterEpis()
      .pipe(
        finalize(() => {
          this.carregando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: (items) => (this.epis = items),
        error: (e) => (this.erro = mensagemErroApi(e)),
      });
  }

  termoBusca: string = '';

  get listaEpisCadastrados() {
    return this.epis.map((e) => e.descricao);
  }

  epis: Epi[] = [];

  entregas: EntregaEpi[] = [];

  mostrarModalEdicao = false;
  epiEmEdicao: Epi = { id: 0, descricao: '', quantidade: 0, inclusao: '', validade: '', ca: '' };

  abrirModalEdicao(epi: Epi) {
    if (this.salvando) return;
    this.salvando = true;
    this.erro = '';
    this.api
      .obterEpiPorId(epi.id)
      .pipe(
        finalize(() => {
          this.salvando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: (item) => {
          this.epiEmEdicao = { ...item };
          this.mostrarModalEdicao = true;
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }

  fecharModalEdicao() {
    if (this.salvando) return;
    this.mostrarModalEdicao = false;
  }

  salvarEdicao(form?: NgForm) {
    if (this.salvando) return;
    const d = this.epiEmEdicao;
    if (form?.invalid || !validarEpi(d)) {
      form?.control.markAllAsTouched();
      this.toast.error('Preencha os campos e uma quantidade inteira não negativa.');
      return;
    }
    const { id, ...dados } = d;
    this.salvando = true;
    this.erro = '';
    this.api
      .atualizarEpi(id, dados)
      .pipe(
        finalize(() => {
          this.salvando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: (item) => {
          this.epis = this.epis.map((e) => (e.id === id ? item : e));
          this.mostrarModalEdicao = false;
          this.toast.success('EPI atualizado com sucesso!');
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }

  filtrarApenasNumerosCa(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input) {
      input.value = input.value.replace(/[^0-9]/g, '').slice(0, 10);
      this.epiEmEdicao.ca = input.value;
    }
  }

  mostrarModalEntrega = false;
  novaEntrega = { colaborador: '', epiId: '', data: '', quantidade: 1 };

  abrirModalEntrega() {
    this.novaEntrega = {
      colaborador: '',
      epiId: '',
      data: new Date().toISOString().split('T')[0],
      quantidade: 1,
    };
    this.mostrarModalEntrega = true;
  }

  fecharModalEntrega() {
    this.mostrarModalEntrega = false;
  }

  salvarEntrega() {
    this.toast.warning('Entregas fora do escopo: não há persistência nem alteração do estoque.');
  }

  get episFiltrados(): Epi[] {
    if (!this.termoBusca) return this.epis;
    const termo = this.termoBusca.toLowerCase();
    return this.epis.filter(
      (e) =>
        e.descricao.toLowerCase().includes(termo) ||
        String(e.id).toLowerCase().includes(termo) ||
        e.ca.includes(termo),
    );
  }

  actionNovoEPI(): void {
    this.router.navigate(['/cadastramentos'], { queryParams: { aba: 'epi' } });
  }
  excluir(item: Epi) {
    if (
      this.salvando ||
      !window.confirm(`Excluir "${item.descricao}"? Esta ação não pode ser desfeita.`)
    )
      return;
    this.salvando = true;
    this.erro = '';
    this.api
      .excluirEpi(item.id)
      .pipe(
        finalize(() => {
          this.salvando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: () => {
          this.epis = this.epis.filter((r) => r.id !== item.id);
          this.toast.success('Registro excluído com sucesso!');
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }
}
