import { validarTreinamento } from '../service/crud-validation';
import { ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';
import { Router } from '@angular/router';
import { DadosReferenciaService } from '../service/dados-referencia.service';
import { ToastService } from '../service/toast.service';
import { Treinamento } from '../models/treinamento.model';
import { TreinamentoService } from '../service/treinamento.service';
import { finalize } from 'rxjs';
import { mensagemErroApi } from '../service/api-error';

interface CardResumo {
  titulo: string;
  total?: number | string;
  icone: string;
}

interface TreinamentoColaborador {
  colaborador: string;
  cargo: string;
  treinamento: string;
  dataConclusao: string;
  status: 'Concluído' | 'Em Andamento' | 'Pendente';
}

interface CertificacaoColaborador {
  colaborador: string;
  cargo: string;
  treinamento: string;
  certificacao: string;
  validade: string;
  status?: 'Ativa' | 'Vencida' | 'Alerta';
}

interface CertificacaoLista {
  id: string;
  treinamento: string;
  instituicao: string;
  cargaHoraria: string;
  validadePadrao: string;
}

interface CargoLnt {
  cargo: string;
  setor: string;
  treinamentosObrigatorios: string;
  status: string;
}

interface CargoLntColaborador {
  colaborador: string;
  cargo: string;
  setor: string;
  treinamentosPendentes: string;
  status: 'Conforme' | 'Pendente';
}

interface ReciclagemItem {
  colaborador: string;
  cargo: string;
  treinamento: string;
  prazoMaximo: string;
  status: string;
}

interface ReciclagemLista {
  turma: string;
  treinamento: string;
  instrutor: string;
  dataAgendada: string;
  vagas: string;
  status: string;
}

interface MatrizCruzadaItem {
  colaborador: string;
  cargo: string;
  nr06: 'OK' | 'Alerta' | 'Vencido' | 'N/A';
  nr11: 'OK' | 'Alerta' | 'Vencido' | 'N/A';
  nr12: 'OK' | 'Alerta' | 'Vencido' | 'N/A';
  nr17: 'OK' | 'Alerta' | 'Vencido' | 'N/A';
  nr35: 'OK' | 'Alerta' | 'Vencido' | 'N/A';
}

@Component({
  selector: 'app-matriz-treinamento',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './matriz-treinamento.html',
  styleUrl: './matriz-treinamento.scss',
})
export class MatrizTreinamentos implements OnInit {
  private api = inject(TreinamentoService);
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
      .listar()
      .pipe(
        finalize(() => {
          this.carregando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: (items) => (this.treinamentos = items),
        error: (e) => (this.erro = mensagemErroApi(e)),
      });
  }
  private router = inject(Router);
  private toast = inject(ToastService);
  private dadosReferencia = inject(DadosReferenciaService);

  cardSelecionado: string = 'Treinamentos';
  modoVisualizacao: 'colaborador' | 'lista' = 'lista';

  mostrarModalCertificacao: boolean = false;
  mostrarModalReciclagem: boolean = false;
  mostrarModalEdicaoGeral: boolean = false;
  itemOriginalReferencia: any = null;
  itemEmEdicao: any = null;

  readonly listaColaboradoresCadastrados: string[] = [];

  readonly listaCargosCadastrados = this.dadosReferencia.cargosCadastrados;

  readonly listaTreinamentosCadastrados: string[] = [];

  readonly listaSetoresCadastrados = this.dadosReferencia.setoresCadastrados;

  get resumos(): CardResumo[] {
    return [
      { titulo: 'Visão Geral', icone: '📊' },
      { titulo: 'LNT / Cargos', icone: '📋' },
      { titulo: 'Treinamentos', total: this.treinamentos.length, icone: '🎓' },
      { titulo: 'Certificações', icone: '🏅' },
      { titulo: 'Reciclagens', icone: '🔄' },
    ];
  }

  treinamentos: Treinamento[] = [];

  treinamentosColaborador: TreinamentoColaborador[] = [];

  certificacoes: CertificacaoColaborador[] = [];

  certificacoesLista: CertificacaoLista[] = [];

  cargosLnt: CargoLnt[] = [];

  cargosLntColaborador: CargoLntColaborador[] = [];

  reciclagens: ReciclagemItem[] = [];

  reciclagensLista: ReciclagemLista[] = [];

  matrizCruzada: MatrizCruzadaItem[] = [];

  selecionarCard(card: string): void {
    this.cardSelecionado = card;
  }

  setModoVisualizacao(modo: 'colaborador' | 'lista'): void {
    this.modoVisualizacao = modo;
  }

  abrirModalCertificacao() {
    this.toast.warning('Função fora do escopo, sem integração com a API.');
  }

  fecharModalCertificacao(): void {
    this.mostrarModalCertificacao = false;
  }

  abrirModalReciclagem() {
    this.toast.warning('Função fora do escopo, sem integração com a API.');
  }

  fecharModalReciclagem(): void {
    this.mostrarModalReciclagem = false;
  }

  salvarVinculoCertificacao() {
    this.toast.warning('Função fora do escopo, sem integração com a API.');
  }

  salvarVinculoReciclagem() {
    this.toast.warning('Função fora do escopo, sem integração com a API.');
  }

  abrirModalEdicaoGeral(item: any) {
    if (this.cardSelecionado !== 'Treinamentos' || this.modoVisualizacao !== 'lista') {
      this.toast.warning('Função fora do escopo, sem persistência.');
      return;
    }
    if (this.salvando) return;
    this.salvando = true;
    this.erro = '';
    this.api
      .buscarPorId(item.id)
      .pipe(
        finalize(() => {
          this.salvando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: (r) => {
          this.itemEmEdicao = { ...r };
          this.mostrarModalEdicaoGeral = true;
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }

  fecharModalEdicaoGeral(): void {
    if (this.salvando) return;
    this.mostrarModalEdicaoGeral = false;
    this.itemOriginalReferencia = null;
    this.itemEmEdicao = null;
  }

  salvarEdicaoGeral(form?: NgForm) {
    if (!this.itemEmEdicao || this.salvando) return;
    if (this.cardSelecionado !== 'Treinamentos' || this.modoVisualizacao !== 'lista') {
      this.toast.warning('Função fora do escopo.');
      return;
    }
    const d = this.itemEmEdicao as Treinamento;
    if (form?.invalid || !validarTreinamento(d)) {
      form?.control.markAllAsTouched();
      this.toast.error('Preencha os campos corretamente.');
      return;
    }
    const { id, ...dados } = d;
    dados.nr = dados.nr?.trim() || null;
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
        next: (r) => {
          this.treinamentos = this.treinamentos.map((t) => (t.id === id ? r : t));
          this.mostrarModalEdicaoGeral = false;
          this.itemEmEdicao = null;
          this.toast.success('Treinamento atualizado com sucesso!');
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }

  navegarParaCadastro(): void {
    const mapaAbas: Record<string, string> = {
      'LNT / Cargos': 'lnt',
      Treinamentos: 'treinamento',
      Reciclagens: 'reciclagem',
    };
    const aba = mapaAbas[this.cardSelecionado] || 'treinamento';
    this.router.navigate(['/cadastramentos'], { queryParams: { aba } });
  }

  exportarMatriz() {
    this.toast.warning('Função fora do escopo, sem integração com a API.');
  }
  excluir(item: Treinamento) {
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
          this.treinamentos = this.treinamentos.filter((r) => r.id !== item.id);
          this.toast.success('Registro excluído com sucesso!');
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }
}
