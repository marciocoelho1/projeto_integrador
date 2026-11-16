import { validarTreinamento } from '../service/crud-validation';
import { ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';
import { Router } from '@angular/router';
import { DadosReferenciaService } from '../service/dados-referencia.service';
import { ToastService } from '../service/toast.service';
import { Treinamento } from '../models/treinamento.model';
import { TreinamentoService } from '../service/treinamento.service';
import { ColaboradorService } from '../service/colaborador.service';
import { Colaborador } from '../models/colaborador.model';
import {
  Certificacao,
  LntCargo,
  LntColaborador,
  StatusTurmaReciclagem,
  StatusVinculo,
  TurmaReciclagem,
  VinculoTreinamento,
} from '../models/treinamento-avancado.model';
import { TreinamentoAvancadoService } from '../service/treinamento-avancado.service';
import { Observable, finalize, forkJoin, map } from 'rxjs';
import { mensagemErroApi } from '../service/api-error';
import { RelatorioService } from '../service/relatorio.service';

interface CardResumo {
  titulo: string;
  total?: number | string;
  icone: string;
}

interface TreinamentoColaborador {
  id?: number;
  colaboradorId?: number;
  treinamentoId?: number;
  colaborador: string;
  cargo: string;
  treinamento: string;
  dataConclusao: string;
  status: StatusVinculo;
  derivado?: boolean;
}

interface CertificacaoColaborador {
  id?: number;
  colaborador: string;
  cargo: string;
  treinamento: string;
  certificacao: string;
  validade: string;
  status?: 'Ativa' | 'Vencida' | 'Alerta';
  derivado?: boolean;
}

interface CertificacaoLista {
  id: string;
  treinamento: string;
  instituicao: string;
  cargaHoraria: string;
  validadePadrao: string;
}

interface CargoLnt {
  id?: number;
  cargo: string;
  setor: string;
  treinamentosObrigatorios: string;
  status: string;
  derivado?: boolean;
}

interface CargoLntColaborador {
  id?: number;
  colaborador: string;
  cargo: string;
  setor: string;
  treinamentosPendentes: string;
  status: 'Conforme' | 'Pendente';
  derivado?: boolean;
}

interface ReciclagemItem {
  id?: number;
  colaborador: string;
  cargo: string;
  treinamento: string;
  prazoMaximo: string;
  status: string;
  derivado?: boolean;
}

interface ReciclagemLista {
  id: number;
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
  derivado?: boolean;
}

interface CertificacaoCadastro {
  colaboradorId: number | null;
  treinamentoId: number | null;
  instituicao: string;
  cargaHoraria: string;
  emitidaEm: string;
  validade: string;
}

interface TurmaCadastro {
  treinamentoId: number | null;
  instrutor: string;
  dataAgendada: string;
  vagas: number | null;
  status: StatusTurmaReciclagem;
}

const JANELA_ALERTA_DIAS = 60;
const NRS_MATRIZ = [
  { chave: 'nr06' as const, nr: 'NR-06' },
  { chave: 'nr11' as const, nr: 'NR-11' },
  { chave: 'nr12' as const, nr: 'NR-12' },
  { chave: 'nr17' as const, nr: 'NR-17' },
  { chave: 'nr35' as const, nr: 'NR-35' },
];

@Component({
  selector: 'app-matriz-treinamento',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './matriz-treinamento.html',
  styleUrl: './matriz-treinamento.scss',
})
export class MatrizTreinamentos implements OnInit {
  private api = inject(TreinamentoService);
  private avancado = inject(TreinamentoAvancadoService);
  private colaboradoresApi = inject(ColaboradorService);
  private cdr = inject(ChangeDetectorRef);
  erro = '';
  carregando = false;
  salvando = false;
  ngOnInit() {
    this.carregar();
  }
  carregar() {
    if (this.carregando) return;
    const requisicao = this.requisicaoDoCard();
    if (!requisicao) return;
    this.carregando = true;
    this.erro = '';
    requisicao
      .pipe(
        finalize(() => {
          this.carregando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }
  private router = inject(Router);
  private toast = inject(ToastService);
  private relatorios = inject(RelatorioService);
  private dadosReferencia = inject(DadosReferenciaService);

  cardSelecionado: string = 'Treinamentos';
  modoVisualizacao: 'colaborador' | 'lista' = 'lista';

  mostrarModalCertificacao: boolean = false;
  mostrarModalReciclagem: boolean = false;
  mostrarModalEdicaoGeral: boolean = false;
  itemOriginalReferencia: any = null;
  itemEmEdicao: any = null;

  colaboradores: Colaborador[] = [];

  treinamentosDisponiveis: Treinamento[] = [];

  listaColaboradoresCadastrados: string[] = [];

  readonly listaCargosCadastrados = this.dadosReferencia.cargosCadastrados;

  listaTreinamentosCadastrados: string[] = [];

  readonly listaSetoresCadastrados = this.dadosReferencia.setoresCadastrados;

  get resumos(): CardResumo[] {
    return [
      { titulo: 'Visão Geral', icone: '📊' },
      { titulo: 'LNT / Cargos', total: this.cargosLnt.length || undefined, icone: '📋' },
      { titulo: 'Treinamentos', total: this.treinamentos.length, icone: '🎓' },
      {
        titulo: 'Certificações',
        total: this.certificacoesLista.length + this.certificacoes.length || undefined,
        icone: '🏅',
      },
      {
        titulo: 'Reciclagens',
        total: this.reciclagens.length + this.reciclagensLista.length || undefined,
        icone: '🔄',
      },
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

  certificacaoEmCadastro: CertificacaoCadastro = {
    colaboradorId: null,
    treinamentoId: null,
    instituicao: '',
    cargaHoraria: '',
    emitidaEm: '',
    validade: '',
  };

  turmaEmCadastro: TurmaCadastro = {
    treinamentoId: null,
    instrutor: '',
    dataAgendada: '',
    vagas: null,
    status: 'Agendada',
  };

  selecionarCard(card: string): void {
    this.cardSelecionado = card;
    this.carregar();
  }

  setModoVisualizacao(modo: 'colaborador' | 'lista'): void {
    if (this.modoVisualizacao === modo) return;
    this.modoVisualizacao = modo;
    this.carregar();
  }

  abrirModalCertificacao() {
    this.certificacaoEmCadastro = {
      colaboradorId: null,
      treinamentoId: null,
      instituicao: '',
      cargaHoraria: '',
      emitidaEm: '',
      validade: '',
    };
    this.carregarReferencias(() => {
      this.mostrarModalCertificacao = true;
      this.cdr.markForCheck();
    });
  }

  fecharModalCertificacao(): void {
    this.mostrarModalCertificacao = false;
  }

  abrirModalReciclagem() {
    this.turmaEmCadastro = {
      treinamentoId: null,
      instrutor: '',
      dataAgendada: '',
      vagas: null,
      status: 'Agendada',
    };
    this.carregarReferencias(() => {
      this.mostrarModalReciclagem = true;
      this.cdr.markForCheck();
    });
  }

  fecharModalReciclagem(): void {
    this.mostrarModalReciclagem = false;
  }

  salvarVinculoCertificacao() {
    if (this.salvando) return;
    const dados = this.certificacaoEmCadastro;
    if (
      !dados.colaboradorId ||
      !dados.treinamentoId ||
      !dados.instituicao.trim() ||
      !dados.cargaHoraria.trim() ||
      !dados.emitidaEm ||
      !dados.validade
    ) {
      this.toast.error('Informe colaborador, treinamento, instituição, carga horária e as datas.');
      return;
    }
    this.salvando = true;
    this.erro = '';
    this.avancado
      .criarCertificacao({
        colaboradorId: dados.colaboradorId,
        treinamentoId: dados.treinamentoId,
        instituicao: dados.instituicao.trim(),
        cargaHoraria: dados.cargaHoraria.trim(),
        emitidaEm: dados.emitidaEm,
        validade: dados.validade,
        arquivoUrl: null,
      })
      .pipe(
        finalize(() => {
          this.salvando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: () => {
          this.mostrarModalCertificacao = false;
          this.toast.success('Certificação cadastrada com sucesso!');
          this.carregar();
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }

  salvarVinculoReciclagem() {
    if (this.salvando) return;
    const dados = this.turmaEmCadastro;
    if (
      !dados.treinamentoId ||
      !dados.instrutor.trim() ||
      !dados.dataAgendada ||
      dados.vagas === null ||
      dados.vagas < 0
    ) {
      this.toast.error('Informe treinamento, instrutor, data agendada e vagas (0 ou mais).');
      return;
    }
    this.salvando = true;
    this.erro = '';
    this.avancado
      .criarTurmaReciclagem({
        treinamentoId: dados.treinamentoId,
        instrutor: dados.instrutor.trim(),
        dataAgendada: dados.dataAgendada,
        vagas: dados.vagas,
        status: dados.status,
      })
      .pipe(
        finalize(() => {
          this.salvando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: () => {
          this.mostrarModalReciclagem = false;
          this.toast.success('Turma de reciclagem cadastrada com sucesso!');
          this.carregar();
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }

  abrirModalEdicaoGeral(item: any) {
    if (this.salvando) return;
    if (item?.derivado || this.cardSelecionado === 'Visão Geral') {
      this.toast.warning(
        'Este registro é calculado a partir dos cargos, vínculos e certificações. Edite o cadastro de origem.',
      );
      return;
    }
    this.itemOriginalReferencia = { ...item };
    if (this.cardSelecionado === 'Treinamentos' && this.modoVisualizacao === 'lista') {
      this.abrirEdicaoTreinamento(item);
      return;
    }
    this.itemEmEdicao = { ...item };
    this.mostrarModalEdicaoGeral = true;
    this.cdr.markForCheck();
  }

  private abrirEdicaoTreinamento(item: any) {
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
    if (form?.invalid) {
      form?.control.markAllAsTouched();
      this.toast.error('Preencha os campos corretamente.');
      return;
    }
    if (this.cardSelecionado === 'Treinamentos' && this.modoVisualizacao === 'lista') {
      this.salvarTreinamento(form);
      return;
    }
    if (this.cardSelecionado === 'Treinamentos') return this.salvarVinculo();
    if (this.cardSelecionado === 'LNT / Cargos') return this.salvarCargo();
    if (this.cardSelecionado === 'Certificações') return this.salvarCertificacao();
    if (this.cardSelecionado === 'Reciclagens') return this.salvarTurmaReciclagem();
    this.toast.warning('Edite o cadastro de origem deste registro calculado.');
  }

  private salvarTreinamento(form?: NgForm) {
    const d = this.itemEmEdicao as Treinamento;
    if (!validarTreinamento(d)) {
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

  private salvarVinculo() {
    const original = this.itemOriginalReferencia as VinculoTreinamento | null;
    if (!original?.id) {
      this.toast.warning('Vínculo sem identificação. Recarregue a lista.');
      return;
    }
    this.salvando = true;
    this.erro = '';
    this.avancado
      .atualizarVinculo(original.id, {
        colaboradorId: original.colaboradorId,
        treinamentoId: original.treinamentoId,
        dataConclusao: this.itemEmEdicao.dataConclusao || null,
        status: this.itemEmEdicao.status,
      })
      .pipe(
        finalize(() => {
          this.salvando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: (r) => {
          this.treinamentosColaborador = this.treinamentosColaborador.map((item) =>
            item.id === r.id ? this.paraTreinamentoColaborador(r) : item,
          );
          this.mostrarModalEdicaoGeral = false;
          this.itemEmEdicao = null;
          this.toast.success('Vínculo atualizado com sucesso!');
          this.carregar();
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }

  private salvarCargo() {
    const original = this.itemOriginalReferencia as CargoLnt | null;
    if (!original?.id) {
      this.toast.warning('Cargo sem identificação. Recarregue a lista.');
      return;
    }
    this.salvando = true;
    this.erro = '';
    this.avancado
      .atualizarCargo(original.id, {
        nome: String(this.itemEmEdicao.cargo ?? '').trim(),
        setor: String(this.itemEmEdicao.setor ?? '').trim(),
        status: this.itemEmEdicao.status,
      })
      .pipe(
        finalize(() => {
          this.salvando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: () => {
          this.mostrarModalEdicaoGeral = false;
          this.itemEmEdicao = null;
          this.toast.success('Cargo atualizado com sucesso!');
          this.carregar();
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }

  private salvarCertificacao() {
    const original = this.itemOriginalReferencia as Certificacao | null;
    if (!original?.id) {
      this.toast.warning('Certificação sem identificação. Recarregue a lista.');
      return;
    }
    const instituicao = String(this.itemEmEdicao.instituicao ?? this.itemEmEdicao.certificacao ?? '').trim();
    const cargaHoraria = String(this.itemEmEdicao.cargaHoraria ?? original.cargaHoraria ?? '').trim();
    const validade = String(this.itemEmEdicao.validade ?? this.itemEmEdicao.validadePadrao ?? '').trim();
    if (!instituicao || !cargaHoraria || !validade) {
      this.toast.error('Informe instituição, carga horária e validade.');
      return;
    }
    this.salvando = true;
    this.erro = '';
    this.avancado
      .atualizarCertificacao(original.id, {
        colaboradorId: original.colaboradorId,
        treinamentoId: original.treinamentoId,
        instituicao,
        cargaHoraria,
        emitidaEm: original.emitidaEm,
        validade,
        arquivoUrl: original.arquivoUrl,
      })
      .pipe(
        finalize(() => {
          this.salvando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: () => {
          this.mostrarModalEdicaoGeral = false;
          this.itemEmEdicao = null;
          this.toast.success('Certificação atualizada com sucesso!');
          this.carregar();
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }

  private salvarTurmaReciclagem() {
    const original = this.itemOriginalReferencia as TurmaReciclagem | null;
    if (!original?.id) {
      this.toast.warning('Turma sem identificação. Recarregue a lista.');
      return;
    }
    const vagas = Number(this.itemEmEdicao.vagas);
    if (!Number.isInteger(vagas) || vagas < 0) {
      this.toast.error('Informe as vagas como número inteiro igual ou maior que zero.');
      return;
    }
    this.salvando = true;
    this.erro = '';
    this.avancado
      .atualizarTurmaReciclagem(original.id, {
        treinamentoId: original.treinamentoId,
        instrutor: String(this.itemEmEdicao.instrutor ?? '').trim(),
        dataAgendada: String(this.itemEmEdicao.dataAgendada ?? '').trim(),
        vagas,
        status: this.itemEmEdicao.status,
      })
      .pipe(
        finalize(() => {
          this.salvando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: () => {
          this.mostrarModalEdicaoGeral = false;
          this.itemEmEdicao = null;
          this.toast.success('Turma de reciclagem atualizada com sucesso!');
          this.carregar();
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
    // O CSV é montado no servidor (GET /api/relatorios/matriz-treinamentos.csv): sai com todos os
    // vínculos gravados no banco, e não só com o que a Visão Geral tinha carregado na tela.
    this.relatorios.baixar('matriz-treinamentos', 'matriz-treinamentos.csv').subscribe({
      next: () => this.toast.success('Matriz cruzada exportada em CSV.'),
      error: () => this.toast.error('Não foi possível gerar o relatório agora.'),
    });
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

  private requisicaoDoCard(): Observable<void> | null {
    const card = this.cardSelecionado;
    const lista = this.modoVisualizacao === 'lista';
    if (card === 'Treinamentos') {
      return lista
        ? this.api.listar().pipe(
            map((items) => {
              this.treinamentos = items;
              this.listaTreinamentosCadastrados = items.map((item) => item.nome);
            }),
          )
        : this.avancado.listarVinculos().pipe(
            map((items) => {
              this.treinamentosColaborador = items.map((item) => this.paraTreinamentoColaborador(item));
            }),
          );
    }
    if (card === 'Visão Geral') {
      return forkJoin({
        cargos: this.avancado.listarLnt(),
        colaboradores: this.avancado.listarLntColaboradores(),
        vinculos: this.avancado.listarVinculos(),
      }).pipe(
        map(({ cargos, colaboradores, vinculos }) => {
          this.cargosLnt = cargos.map((cargo) => this.paraLntCargo(cargo));
          this.cargosLntColaborador = colaboradores.map((item) => this.paraLntColaborador(item));
          this.matrizCruzada = colaboradores.map((item) => this.paraMatrizCruzada(item, cargos, vinculos));
        }),
      );
    }
    if (card === 'LNT / Cargos') {
      return lista
        ? this.avancado.listarLnt().pipe(
            map((cargos) => {
              this.cargosLnt = cargos.map((cargo) => this.paraLntCargo(cargo));
            }),
          )
        : this.avancado.listarLntColaboradores().pipe(
            map((colaboradores) => {
              this.cargosLntColaborador = colaboradores.map((item) => this.paraLntColaborador(item));
            }),
          );
    }
    if (card === 'Certificações') {
      return this.avancado.listarCertificacoes().pipe(
        map((certificacoes) => {
          this.certificacoes = certificacoes.map((item) => this.paraCertificacaoColaborador(item));
          this.certificacoesLista = certificacoes.map((item) => this.paraCertificacaoLista(item));
        }),
      );
    }
    if (card === 'Reciclagens') {
      return lista
        ? this.avancado.listarTurmasReciclagem().pipe(
            map((turmas) => {
              this.reciclagensLista = turmas.map((turma) => this.paraTurmaReciclagem(turma));
            }),
          )
        : this.avancado.listarReciclagens().pipe(
            map((reciclagens) => {
              this.reciclagens = reciclagens.map((item) => ({
                colaborador: item.colaborador,
                cargo: item.cargo,
                treinamento: item.treinamento,
                prazoMaximo: item.prazoMaximo,
                status: item.status,
                derivado: true,
              }));
            }),
          );
    }
    return null;
  }

  private carregarReferencias(aoConcluir: () => void) {
    if (this.colaboradores.length && this.listaTreinamentosCadastrados.length) {
      aoConcluir();
      return;
    }
    this.carregando = true;
    this.erro = '';
    forkJoin({
      colaboradores: this.colaboradoresApi.listar(),
      treinamentos: this.api.listar(),
    })
      .pipe(
        finalize(() => {
          this.carregando = false;
          this.cdr.markForCheck();
        }),
      )
      .subscribe({
        next: ({ colaboradores, treinamentos }) => {
          this.colaboradores = colaboradores;
          this.treinamentosDisponiveis = treinamentos;
          this.listaColaboradoresCadastrados = colaboradores.map((item) => item.nome);
          this.listaTreinamentosCadastrados = treinamentos.map((item) => item.nome);
          aoConcluir();
        },
        error: (e) => {
          this.erro = mensagemErroApi(e);
          this.toast.error(this.erro);
        },
      });
  }

  private paraTreinamentoColaborador(item: VinculoTreinamento): TreinamentoColaborador {
    return {
      id: item.id,
      colaboradorId: item.colaboradorId,
      treinamentoId: item.treinamentoId,
      colaborador: item.colaborador,
      cargo: item.cargo,
      treinamento: item.treinamento,
      dataConclusao: item.dataConclusao ?? '',
      status: item.status,
    };
  }

  private paraLntCargo(cargo: LntCargo): CargoLnt {
    const obrigatorios = cargo.treinamentos.filter((item) => item.obrigatorio);
    const nomes = obrigatorios.map((item) => item.treinamento);
    return {
      id: cargo.id,
      cargo: cargo.cargo,
      setor: cargo.setor,
      treinamentosObrigatorios: nomes.length ? nomes.join(', ') : 'Nenhum treinamento obrigatório',
      status: cargo.status,
    };
  }

  private paraLntColaborador(item: LntColaborador): CargoLntColaborador {
    return {
      id: item.colaboradorId,
      colaborador: item.colaborador,
      cargo: item.cargo,
      setor: item.setor,
      treinamentosPendentes: item.treinamentosPendentes.length
        ? item.treinamentosPendentes.join(', ')
        : 'Nenhum',
      status: item.status,
      derivado: true,
    };
  }

  private paraCertificacaoColaborador(item: Certificacao): CertificacaoColaborador {
    return {
      id: item.id,
      colaborador: item.colaborador,
      cargo: item.cargo,
      treinamento: item.treinamento,
      certificacao: item.instituicao,
      validade: item.validade,
      status: item.status,
    };
  }

  private paraCertificacaoLista(item: Certificacao): CertificacaoLista {
    return {
      id: `#${item.id}`,
      treinamento: item.treinamento,
      instituicao: item.instituicao,
      cargaHoraria: item.cargaHoraria,
      validadePadrao: item.validade,
    };
  }

  private paraTurmaReciclagem(turma: TurmaReciclagem): ReciclagemLista {
    return {
      id: turma.id,
      turma: `#${turma.id}`,
      treinamento: turma.treinamento,
      instrutor: turma.instrutor,
      dataAgendada: turma.dataAgendada,
      vagas: String(turma.vagas),
      status: turma.status,
    };
  }

  private paraMatrizCruzada(
    colaborador: LntColaborador,
    cargos: LntCargo[],
    vinculos: VinculoTreinamento[],
  ): MatrizCruzadaItem {
    const matrizDoCargo = cargos.find((cargo) => cargo.cargo === colaborador.cargo);
    const row: any = { colaborador: colaborador.colaborador, cargo: colaborador.cargo, derivado: true };
    for (const coluna of NRS_MATRIZ) {
      row[coluna.chave] = this.statusDaNr(coluna.nr, matrizDoCargo, colaborador.colaboradorId, vinculos);
    }
    return row as MatrizCruzadaItem;
  }

  private statusDaNr(
    nr: string,
    matrizDoCargo: LntCargo | undefined,
    colaboradorId: number,
    vinculos: VinculoTreinamento[],
  ): 'OK' | 'Alerta' | 'Vencido' | 'N/A' {
    const exigido = (matrizDoCargo?.treinamentos ?? []).find(
      (item) => item.obrigatorio && (item.nr ?? '').toUpperCase().includes(nr),
    );
    if (!exigido) return 'N/A';
    const vinculo = vinculos.find(
      (item) => item.colaboradorId === colaboradorId && item.treinamentoId === exigido.treinamentoId,
    );
    if (!vinculo) return 'Vencido';
    if (vinculo.status !== 'Concluído') return 'Alerta';
    if (!vinculo.validade) return 'OK';
    const dias = this.diasAte(vinculo.validade);
    if (dias < 0) return 'Vencido';
    return dias <= JANELA_ALERTA_DIAS ? 'Alerta' : 'OK';
  }

  private diasAte(data: string): number {
    const alvo = new Date(`${data}T00:00:00`);
    const hoje = new Date();
    hoje.setHours(0, 0, 0, 0);
    return Math.round((alvo.getTime() - hoje.getTime()) / 86400000);
  }
}
