import { validarEpi } from '../service/crud-validation';
import { ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';
import { Router } from '@angular/router';
import { ToastService } from '../service/toast.service';
import { EpisService, Epi, EntregaEpi, EntregaEpiRequest } from '../service/epis.service';
import { ColaboradorService } from '../service/colaborador.service';
import { Colaborador } from '../models/colaborador.model';
import { finalize } from 'rxjs';
import { mensagemErroApi } from '../service/api-error';

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
  private apiColaboradores = inject(ColaboradorService);
  private cdr = inject(ChangeDetectorRef);
  erro = '';
  carregando = false;
  salvando = false;
  carregandoEntregas = false;
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

  carregarEntregas() {
    if (this.carregandoEntregas) return;
    this.carregandoEntregas = true;
    this.api
      .obterEntregas()
      .pipe(
        finalize(() => {
          this.carregandoEntregas = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: (items) => (this.entregas = items),
        error: (e) => (this.erro = mensagemErroApi(e)),
      });
  }

  carregarColaboradores() {
    this.apiColaboradores.listar().subscribe({
      next: (items) => {
        this.colaboradores = items;
        this.cdr.markForCheck();
      },
      error: (e) => (this.erro = mensagemErroApi(e)),
    });
  }

  /** Recarrega estoque e entregas: usado pelo botão "Atualizar lista". */
  atualizarListas() {
    this.carregar();
    this.carregarEntregas();
  }

  termoBusca: string = '';

  get listaEpisCadastrados() {
    return this.epis.map((e) => e.descricao);
  }

  get listaColaboradoresCadastrados() {
    return this.colaboradores.map((c) => c.nome);
  }

  epis: Epi[] = [];

  colaboradores: Colaborador[] = [];

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
    // Carrega os colaboradores só quando o modal abre, para resolver o nome digitado em um id.
    this.carregarColaboradores();
  }

  fecharModalEntrega() {
    this.mostrarModalEntrega = false;
  }

  /** Registra a entrega na API (abate o estoque no servidor) e recarrega estoque e entregas. */
  salvarEntrega() {
    if (this.salvando) return;
    const nome = this.novaEntrega.colaborador.trim().toLowerCase();
    const colaborador = this.colaboradores.find(
      (c) => c.nome.trim().toLowerCase() === nome || c.matricula.trim().toLowerCase() === nome,
    );
    const epiId = Number(this.novaEntrega.epiId);
    const quantidade = Number(this.novaEntrega.quantidade);
    if (
      !colaborador ||
      !Number.isInteger(epiId) ||
      epiId <= 0 ||
      !Number.isInteger(quantidade) ||
      quantidade <= 0 ||
      !this.novaEntrega.data
    ) {
      this.toast.error(
        'Selecione um colaborador cadastrado, o EPI, uma quantidade inteira maior que zero e a data.',
      );
      return;
    }
    const dados: EntregaEpiRequest = {
      colaboradorId: colaborador.id,
      epiId,
      quantidade,
      dataEntrega: this.novaEntrega.data,
      assinatura: colaborador.nome,
    };
    this.salvando = true;
    this.erro = '';
    this.api
      .registrarEntrega(dados)
      .pipe(
        finalize(() => {
          this.salvando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: () => {
          this.mostrarModalEntrega = false;
          this.toast.success('Entrega registrada e estoque atualizado!');
          this.carregar();
          this.carregarEntregas();
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }

  /** Exclui a entrega (a API estorna a quantidade ao estoque) e recarrega as listas. */
  excluirEntrega(entrega: EntregaEpi) {
    if (
      this.salvando ||
      !window.confirm(`Excluir a entrega de "${entrega.epi}"? O estoque será estornado.`)
    )
      return;
    this.salvando = true;
    this.erro = '';
    this.api
      .excluirEntrega(entrega.id)
      .pipe(
        finalize(() => {
          this.salvando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: () => {
          this.toast.success('Entrega excluída e estoque estornado!');
          this.carregar();
          this.carregarEntregas();
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
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
