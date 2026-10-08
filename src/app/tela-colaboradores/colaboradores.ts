import { validarColaborador } from '../service/crud-validation';
import { ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';
import { Router } from '@angular/router';
import { finalize } from 'rxjs';
import { ToastService } from '../service/toast.service';
import { Colaborador } from '../models/colaborador.model';
import { ColaboradorService } from '../service/colaborador.service';
import { mensagemErroApi } from '../service/api-error';
@Component({
  selector: 'app-colaboradores',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './colaboradores.html',
  styleUrls: ['./colaboradores.scss'],
})
export class Colaboradores implements OnInit {
  private router = inject(Router);
  private toast = inject(ToastService);
  private api = inject(ColaboradorService);
  private cdr = inject(ChangeDetectorRef);
  termoBusca = '';
  erro = '';
  carregando = false;
  salvando = false;
  colaboradores: Colaborador[] = [];
  mostrarModalDetalhes = false;
  colaboradorEmEdicao: Colaborador | null = null;
  ngOnInit() {
    this.carregar();
  }
  carregar() {
    if (this.carregando) return;
    this.carregando = true;
    this.erro = '';
    this.api
      .listar()
      .pipe(
        finalize(() => {
          this.carregando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: (items) => (this.colaboradores = items),
        error: (e) => (this.erro = mensagemErroApi(e)),
      });
  }
  get colaboradoresFiltrados() {
    const t = this.termoBusca.trim().toLowerCase();
    return this.colaboradores.filter((c) =>
      [c.nome, c.matricula, c.cpf, c.email, c.cargo, c.setor, c.status].some((v) =>
        v.toLowerCase().includes(t),
      ),
    );
  }
  abrirModalDetalhes(c: Colaborador) {
    if (this.salvando) return;
    this.salvando = true;
    this.erro = '';
    this.api
      .buscarPorId(c.id)
      .pipe(
        finalize(() => {
          this.salvando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: (item) => {
          this.colaboradorEmEdicao = { ...item };
          this.mostrarModalDetalhes = true;
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }
  fecharModalDetalhes() {
    if (this.salvando) return;
    this.mostrarModalDetalhes = false;
    this.colaboradorEmEdicao = null;
  }
  salvarEdicaoDetalhes(form: NgForm) {
    const d = this.colaboradorEmEdicao;
    if (!d || this.salvando) return;
    if (form.invalid || !validarColaborador(d)) {
      form.control.markAllAsTouched();
      this.toast.error('Informe os campos obrigatórios, CPF e e-mail válidos.');
      return;
    }
    const { id, ...dados } = d;
    this.salvando = true;
    this.erro = '';
    this.api
      .atualizar(id, dados)
      .pipe(
        finalize(() => {
          this.salvando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: (item) => {
          this.colaboradores = this.colaboradores.map((c) => (c.id === id ? item : c));
          this.mostrarModalDetalhes = false;
          this.colaboradorEmEdicao = null;
          this.toast.success('Colaborador atualizado com sucesso!');
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }
  actionVerDetalhes(c: Colaborador) {
    this.abrirModalDetalhes(c);
  }
  obterEpis(nome: string): { nome: string; dataEntrega: string; ca: string }[] {
    return [];
  }
  obterTreinamentos(nome: string): { treinamento: string; validade: string; status: string }[] {
    return [];
  }
  obterReciclagens(nome: string): { treinamento: string; prazo: string; status: string }[] {
    return [];
  }
  actionNovoColaborador() {
    this.router.navigate(['/cadastramentos'], { queryParams: { aba: 'colaborador' } });
  }
  excluir(item: Colaborador) {
    if (
      this.salvando ||
      !window.confirm(`Excluir "${item.nome}"? Esta ação não pode ser desfeita.`)
    )
      return;
    this.salvando = true;
    this.erro = '';
    this.api
      .excluir(item.id)
      .pipe(
        finalize(() => {
          this.salvando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: () => {
          this.colaboradores = this.colaboradores.filter((r) => r.id !== item.id);
          this.toast.success('Registro excluído com sucesso!');
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }
}
