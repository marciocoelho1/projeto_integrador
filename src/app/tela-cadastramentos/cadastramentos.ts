import { validarColaborador, validarTreinamento, validarEpi } from '../service/crud-validation';
import { ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { finalize } from 'rxjs';
import { ToastService } from '../service/toast.service';
import { DadosReferenciaService } from '../service/dados-referencia.service';
import { ColaboradorRequest } from '../models/colaborador.model';
import { TreinamentoRequest } from '../models/treinamento.model';
import { ColaboradorService } from '../service/colaborador.service';
import { TreinamentoService } from '../service/treinamento.service';
import { EpisService, EpiRequest } from '../service/epis.service';
import { mensagemErroApi } from '../service/api-error';
@Component({
  selector: 'app-cadastramentos',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './cadastramentos.html',
  styleUrls: ['./cadastramentos.scss'],
})
export class Cadastramentos implements OnInit {
  private route = inject(ActivatedRoute);
  private toast = inject(ToastService);
  private cdr = inject(ChangeDetectorRef);
  private colaboradores = inject(ColaboradorService);
  private treinamentos = inject(TreinamentoService);
  private epis = inject(EpisService);
  private referencia = inject(DadosReferenciaService);
  readonly cargosCadastrados = this.referencia.cargosCadastrados;
  readonly setoresCadastrados = this.referencia.setoresCadastrados;
  novoColaborador: ColaboradorRequest = {
    matricula: '',
    nome: '',
    cpf: '',
    email: '',
    cargo: '',
    setor: '',
    status: 'Ativo',
  };
  novoTreinamento: TreinamentoRequest = {
    codigo: '',
    nome: '',
    classificacao: '',
    nr: null,
    cargaHoraria: '',
    validadeMeses: null,
    status: 'Ativo',
  };
  novoEpi: EpiRequest = { descricao: '', ca: '', inclusao: '', validade: '', quantidade: 0 };
  salvandoColaborador = false;
  salvandoTreinamento = false;
  salvandoEpi = false;
  erro = '';
  abaAtual: 'colaborador' | 'treinamento' | 'epi' | 'lnt' | 'reciclagem' = 'colaborador';
  ngOnInit() {
    this.route.queryParams.subscribe((p) => {
      if (['colaborador', 'treinamento', 'epi', 'lnt', 'reciclagem'].includes(p['aba']))
        this.abaAtual = p['aba'];
    });
  }
  private valido(form: NgForm): boolean {
    if (form.invalid) {
      form.control.markAllAsTouched();
      this.toast.error('Preencha os campos obrigatórios corretamente.');
      return false;
    }
    return true;
  }
  salvarColaborador(form: NgForm) {
    if (this.salvandoColaborador || !this.valido(form)) return;
    const d = this.novoColaborador;
    if (!validarColaborador(d)) {
      this.toast.error('Confira os campos, tamanhos máximos, CPF com 11 dígitos e e-mail válido.');
      return;
    }
    this.salvandoColaborador = true;
    this.erro = '';
    const dados: ColaboradorRequest = {
      matricula: d.matricula.trim(),
      nome: d.nome.trim(),
      cpf: d.cpf.trim(),
      email: d.email.trim(),
      cargo: d.cargo.trim(),
      setor: d.setor.trim(),
      status: d.status,
    };
    this.colaboradores
      .criar(dados)
      .pipe(
        finalize(() => {
          this.salvandoColaborador = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: () => {
          this.toast.success('Colaborador cadastrado com sucesso!');
          form.resetForm({
            matricula: '',
            nome: '',
            cpf: '',
            email: '',
            cargo: '',
            setor: '',
            status: 'Ativo',
          });
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }
  salvarTreinamento(form: NgForm) {
    if (this.salvandoTreinamento || !this.valido(form)) return;
    const d = this.novoTreinamento;
    if (!validarTreinamento(d)) {
      this.toast.error('Confira os campos e a validade inteira não negativa dentro dos limites.');
      return;
    }
    this.salvandoTreinamento = true;
    this.erro = '';
    const dados: TreinamentoRequest = {
      codigo: d.codigo.trim(),
      nome: d.nome.trim(),
      classificacao: d.classificacao.trim(),
      nr: d.nr?.trim() || null,
      cargaHoraria: d.cargaHoraria.trim(),
      validadeMeses: d.validadeMeses,
      status: d.status,
    };
    this.treinamentos
      .criar(dados)
      .pipe(
        finalize(() => {
          this.salvandoTreinamento = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: () => {
          this.toast.success('Treinamento cadastrado com sucesso!');
          form.resetForm({
            codigo: '',
            nome: '',
            classificacao: '',
            nr: null,
            cargaHoraria: '',
            validadeMeses: null,
            status: 'Ativo',
          });
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }
  salvarEPI(form: NgForm) {
    if (this.salvandoEpi || !this.valido(form)) return;
    const d = this.novoEpi;
    if (!validarEpi(d)) {
      this.toast.error(
        'Confira os campos, datas e quantidade inteira não negativa dentro dos limites.',
      );
      return;
    }
    this.salvandoEpi = true;
    this.erro = '';
    const dados: EpiRequest = {
      descricao: d.descricao.trim(),
      ca: d.ca.trim(),
      quantidade: d.quantidade,
      inclusao: d.inclusao,
      validade: d.validade,
    };
    this.epis
      .cadastrarEpi(dados)
      .pipe(
        finalize(() => {
          this.salvandoEpi = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: () => {
          this.toast.success('EPI cadastrado com sucesso!');
          form.resetForm({ descricao: '', ca: '', inclusao: '', validade: '', quantidade: 0 });
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }
  salvarLnt() {
    this.toast.warning('LNT / Cargos: funcionalidade fora do escopo, sem persistência.');
  }
  salvarReciclagem() {
    this.toast.warning('Reciclagens: funcionalidade fora do escopo, sem persistência.');
  }
}
