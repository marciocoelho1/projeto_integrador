import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { DadosReferenciaService } from '../service/dados-referencia.service';
import { ToastService } from '../service/toast.service';

interface CardResumo {
  titulo: string;
  total?: number | string;
  icone: string;
}

interface Treinamento {
  codigo?: string;
  nome: string;
  classificacao: string;
  nr: string;
  cargaHoraria: string;
  validadeMeses?: number;
  status: 'Ativo' | 'Inativo';
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
export class MatrizTreinamentos {
  private router = inject(Router);
  private toast = inject(ToastService);
  private dadosReferencia = inject(DadosReferenciaService);

  cardSelecionado: string = 'Visão Geral';
  modoVisualizacao: 'colaborador' | 'lista' = 'colaborador';

  mostrarModalCertificacao: boolean = false;
  mostrarModalReciclagem: boolean = false;
  mostrarModalEdicaoGeral: boolean = false;
  itemOriginalReferencia: any = null;
  itemEmEdicao: any = null;

  readonly listaColaboradoresCadastrados: string[] = [
    'Carlos Eduardo Silva',
    'Maria Joana Oliveira',
    'Roberto Alves',
    'Ana Paula Souza',
    'Fernando Costa',
    'Lucas Fontes',
    'Juliana Mendes',
  ];

  readonly listaCargosCadastrados = this.dadosReferencia.cargosCadastrados;

  readonly listaTreinamentosCadastrados: string[] = [
    'NR-06 Uso Adequado e Guarda de EPIs',
    'NR-06 Uso Adequado de EPIs',
    'NR-11 Operação Segura de Empilhadeira e Transpaleteira',
    'NR-11 Operação Segura de Empilhadeira',
    'NR-11 Operação de Empilhadeira',
    'NR-12 Segurança em Máquinas (Fatiadores/Serras de Fita)',
    'NR-12 Segurança em Máquinas (Açougue)',
    'NR-12 Segurança em Máquinas (Padaria)',
    'NR-12 Segurança em Máquinas',
    'NR-17 Ergonomia para Operadores de Checkout',
    'NR-17 Ergonomia para Checkout',
    'NR-17 Ergonomia e Postura de Caixa',
    'NR-35 Trabalho em Altura e Manutenção de Gôndolas',
    'NR-35 Trabalho em Altura',
    'NR-23 e Brigada de Incêndio e Evacuação',
    'NR-23 e Brigada de Incêndio',
    'NR-23 e Brigada de Emergência',
    'Boas Práticas de Manipulação de Alimentos',
    'Boas Práticas de Manipulação',
    'Boas Práticas de Higiene e Manipulação',
    'Noções de Primeiros Socorros no Varejo',
  ];

  readonly listaSetoresCadastrados = this.dadosReferencia.setoresCadastrados;

  resumos: CardResumo[] = [
    { titulo: 'Visão Geral', icone: '📊' },
    { titulo: 'LNT / Cargos', total: 14, icone: '📋' },
    { titulo: 'Treinamentos', total: 8, icone: '🎓' },
    { titulo: 'Certificações', total: 45, icone: '🏅' },
    { titulo: 'Reciclagens', total: 7, icone: '🔄' },
  ];

  treinamentos: Treinamento[] = [
    {
      codigo: 'TRN-001',
      nome: 'NR-06 Uso Adequado e Guarda de EPIs',
      classificacao: 'Obrigatório',
      nr: 'NR-06',
      cargaHoraria: '4h',
      validadeMeses: 12,
      status: 'Ativo',
    },
    {
      codigo: 'TRN-002',
      nome: 'NR-11 Operação Segura de Empilhadeira e Transpaleteira',
      classificacao: 'Específico',
      nr: 'NR-11',
      cargaHoraria: '16h',
      validadeMeses: 24,
      status: 'Ativo',
    },
    {
      codigo: 'TRN-003',
      nome: 'NR-12 Segurança em Máquinas (Fatiadores/Serras de Fita)',
      classificacao: 'Obrigatório',
      nr: 'NR-12',
      cargaHoraria: '8h',
      validadeMeses: 24,
      status: 'Ativo',
    },
    {
      codigo: 'TRN-004',
      nome: 'NR-17 Ergonomia para Operadores de Checkout',
      classificacao: 'Obrigatório',
      nr: 'NR-17',
      cargaHoraria: '4h',
      validadeMeses: 24,
      status: 'Ativo',
    },
    {
      codigo: 'TRN-005',
      nome: 'NR-35 Trabalho em Altura e Manutenção de Gôndolas',
      classificacao: 'Específico',
      nr: 'NR-35',
      cargaHoraria: '8h',
      validadeMeses: 24,
      status: 'Ativo',
    },
    {
      codigo: 'TRN-006',
      nome: 'NR-23 e Brigada de Incêndio e Evacuação',
      classificacao: 'Obrigatório',
      nr: 'NR-23',
      cargaHoraria: '8h',
      validadeMeses: 12,
      status: 'Ativo',
    },
    {
      codigo: 'TRN-007',
      nome: 'Boas Práticas de Manipulação de Alimentos',
      classificacao: 'Setorial',
      nr: 'RDC 216',
      cargaHoraria: '6h',
      validadeMeses: 12,
      status: 'Ativo',
    },
    {
      codigo: 'TRN-008',
      nome: 'Noções de Primeiros Socorros no Varejo',
      classificacao: 'Recomendado',
      nr: 'Geral',
      cargaHoraria: '4h',
      validadeMeses: 12,
      status: 'Ativo',
    },
  ];

  treinamentosColaborador: TreinamentoColaborador[] = [
    {
      colaborador: 'Carlos Eduardo Silva',
      cargo: 'Operador de Empilhadeira',
      treinamento: 'NR-11 Operação Segura de Empilhadeira',
      dataConclusao: '15/01/2025',
      status: 'Concluído',
    },
    {
      colaborador: 'Maria Joana Oliveira',
      cargo: 'Açougueira',
      treinamento: 'NR-12 Segurança em Máquinas (Açougue)',
      dataConclusao: '10/02/2024',
      status: 'Concluído',
    },
    {
      colaborador: 'Roberto Alves',
      cargo: 'Operador de Caixa',
      treinamento: 'NR-17 Ergonomia para Checkout',
      dataConclusao: '05/08/2025',
      status: 'Concluído',
    },
    {
      colaborador: 'Ana Paula Souza',
      cargo: 'Repositora',
      treinamento: 'NR-35 Trabalho em Altura',
      dataConclusao: '20/03/2024',
      status: 'Concluído',
    },
    {
      colaborador: 'Fernando Costa',
      cargo: 'Padeiro',
      treinamento: 'NR-12 Segurança em Máquinas (Padaria)',
      dataConclusao: '11/11/2024',
      status: 'Concluído',
    },
    {
      colaborador: 'Lucas Fontes',
      cargo: 'Operador de Empilhadeira',
      treinamento: 'NR-11 Operação de Empilhadeira',
      dataConclusao: '-',
      status: 'Em Andamento',
    },
    {
      colaborador: 'Juliana Mendes',
      cargo: 'Operadora de Caixa',
      treinamento: 'NR-06 Uso Adequado de EPIs',
      dataConclusao: '01/09/2025',
      status: 'Concluído',
    },
  ];

  certificacoes: CertificacaoColaborador[] = [
    {
      colaborador: 'Carlos Eduardo Silva',
      cargo: 'Operador de Empilhadeira',
      treinamento: 'NR-11 Operação Segura de Empilhadeira',
      certificacao: '15/01/2025',
      validade: '14/01/2027',
      status: 'Ativa',
    },
    {
      colaborador: 'Maria Joana Oliveira',
      cargo: 'Açougueira',
      treinamento: 'NR-12 Segurança em Máquinas (Açougue)',
      certificacao: '10/02/2024',
      validade: '09/02/2026',
      status: 'Vencida',
    },
    {
      colaborador: 'Roberto Alves',
      cargo: 'Operador de Caixa',
      treinamento: 'NR-17 Ergonomia para Checkout',
      certificacao: '05/08/2025',
      validade: '04/08/2027',
      status: 'Ativa',
    },
    {
      colaborador: 'Ana Paula Souza',
      cargo: 'Repositora',
      treinamento: 'NR-35 Trabalho em Altura',
      certificacao: '20/03/2024',
      validade: '19/03/2026',
      status: 'Alerta',
    },
    {
      colaborador: 'Fernando Costa',
      cargo: 'Padeiro',
      treinamento: 'NR-12 Segurança em Máquinas (Padaria)',
      certificacao: '11/11/2024',
      validade: '10/11/2026',
      status: 'Ativa',
    },
    {
      colaborador: 'Juliana Mendes',
      cargo: 'Operadora de Caixa',
      treinamento: 'NR-06 Uso Adequado de EPIs',
      certificacao: '01/09/2025',
      validade: '31/08/2026',
      status: 'Ativa',
    },
  ];

  certificacoesLista: CertificacaoLista[] = [
    {
      id: 'CRT-2025-001',
      treinamento: 'NR-06 Uso Adequado e Guarda de EPIs',
      instituicao: 'SST Corporativo',
      cargaHoraria: '4h',
      validadePadrao: '12 meses',
    },
    {
      id: 'CRT-2025-002',
      treinamento: 'NR-11 Operação Segura de Empilhadeira',
      instituicao: 'SENAI Formação Técnica',
      cargaHoraria: '16h',
      validadePadrao: '24 meses',
    },
    {
      id: 'CRT-2025-003',
      treinamento: 'NR-12 Segurança em Máquinas e Equipamentos',
      instituicao: 'Engenharia de Segurança Externa',
      cargaHoraria: '8h',
      validadePadrao: '24 meses',
    },
    {
      id: 'CRT-2025-004',
      treinamento: 'NR-17 Ergonomia e Postura de Caixa',
      instituicao: 'ErgoSeg Consultoria',
      cargaHoraria: '4h',
      validadePadrao: '24 meses',
    },
    {
      id: 'CRT-2025-005',
      treinamento: 'NR-35 Trabalho em Altura',
      instituicao: 'SENAI Formação Técnica',
      cargaHoraria: '8h',
      validadePadrao: '24 meses',
    },
    {
      id: 'CRT-2025-006',
      treinamento: 'NR-23 e Brigada de Emergência',
      instituicao: 'Corpo de Bombeiros / Credenciada',
      cargaHoraria: '8h',
      validadePadrao: '12 meses',
    },
    {
      id: 'CRT-2025-007',
      treinamento: 'Boas Práticas de Higiene e Manipulação',
      instituicao: 'Qualidade & Alimentos Treinamentos',
      cargaHoraria: '6h',
      validadePadrao: '12 meses',
    },
  ];

  cargosLnt: CargoLnt[] = [
    {
      cargo: 'Açougueiro',
      setor: 'Açougue',
      treinamentosObrigatorios: 'NR-06, NR-12, Boas Práticas',
      status: 'Ativo',
    },
    {
      cargo: 'Operador de Caixa',
      setor: 'Frente de Loja',
      treinamentosObrigatorios: 'NR-06, NR-17',
      status: 'Ativo',
    },
    {
      cargo: 'Repositor',
      setor: 'Mercearia',
      treinamentosObrigatorios: 'NR-06, NR-11 (Manual), NR-35',
      status: 'Ativo',
    },
    {
      cargo: 'Padeiro / Confeiteiro',
      setor: 'Padaria',
      treinamentosObrigatorios: 'NR-06, NR-12, Boas Práticas',
      status: 'Ativo',
    },
    {
      cargo: 'Operador de Empilhadeira',
      setor: 'Estoque / Logística',
      treinamentosObrigatorios: 'NR-06, NR-11',
      status: 'Ativo',
    },
    {
      cargo: 'Fiscal de Prevenção de Perdas',
      setor: 'Frente de Loja',
      treinamentosObrigatorios: 'NR-06, Brigada de Incêndio',
      status: 'Ativo',
    },
    {
      cargo: 'Auxiliar de Limpeza',
      setor: 'Higienização',
      treinamentosObrigatorios: 'NR-06 (Químicos), Boas Práticas',
      status: 'Ativo',
    },
  ];

  cargosLntColaborador: CargoLntColaborador[] = [
    {
      colaborador: 'Carlos Eduardo Silva',
      cargo: 'Operador de Empilhadeira',
      setor: 'Estoque / Logística',
      treinamentosPendentes: 'Nenhum (100% Conforme)',
      status: 'Conforme',
    },
    {
      colaborador: 'Maria Joana Oliveira',
      cargo: 'Açougueira',
      setor: 'Açougue',
      treinamentosPendentes: 'NR-12 (Vencido)',
      status: 'Pendente',
    },
    {
      colaborador: 'Roberto Alves',
      cargo: 'Operador de Caixa',
      setor: 'Frente de Loja',
      treinamentosPendentes: 'Nenhum (100% Conforme)',
      status: 'Conforme',
    },
    {
      colaborador: 'Ana Paula Souza',
      cargo: 'Repositora',
      setor: 'Mercearia',
      treinamentosPendentes: 'NR-35 (Vencendo)',
      status: 'Pendente',
    },
    {
      colaborador: 'Fernando Costa',
      cargo: 'Padeiro',
      setor: 'Padaria',
      treinamentosPendentes: 'Nenhum (100% Conforme)',
      status: 'Conforme',
    },
    {
      colaborador: 'Lucas Fontes',
      cargo: 'Operador de Empilhadeira',
      setor: 'Estoque / Logística',
      treinamentosPendentes: 'NR-11 (Em Andamento)',
      status: 'Pendente',
    },
    {
      colaborador: 'Juliana Mendes',
      cargo: 'Operadora de Caixa',
      setor: 'Frente de Loja',
      treinamentosPendentes: 'Nenhum (100% Conforme)',
      status: 'Conforme',
    },
  ];

  reciclagens: ReciclagemItem[] = [
    {
      colaborador: 'Maria Joana Oliveira',
      cargo: 'Açougueira',
      treinamento: 'NR-12 Segurança em Máquinas',
      prazoMaximo: '28/02/2026',
      status: 'Vencido',
    },
    {
      colaborador: 'Ana Paula Souza',
      cargo: 'Repositora',
      treinamento: 'NR-35 Trabalho em Altura',
      prazoMaximo: '19/03/2026',
      status: 'Próximo do Vencimento',
    },
    {
      colaborador: 'Lucas Fontes',
      cargo: 'Operador de Empilhadeira',
      treinamento: 'NR-11 Operação de Empilhadeira',
      prazoMaximo: '05/04/2026',
      status: 'Pendente',
    },
    {
      colaborador: 'Carlos Eduardo Silva',
      cargo: 'Operador de Empilhadeira',
      treinamento: 'NR-06 Uso Adequado de EPIs',
      prazoMaximo: '15/04/2026',
      status: 'Agendado',
    },
    {
      colaborador: 'Fernando Costa',
      cargo: 'Padeiro',
      treinamento: 'Boas Práticas de Manipulação',
      prazoMaximo: '30/04/2026',
      status: 'Pendente',
    },
  ];

  reciclagensLista: ReciclagemLista[] = [
    {
      turma: 'REC-2026-01',
      treinamento: 'NR-12 Segurança em Máquinas',
      instrutor: 'Eng. Marcelo TST',
      dataAgendada: '05/03/2026',
      vagas: '12 / 15',
      status: 'Inscrições Abertas',
    },
    {
      turma: 'REC-2026-02',
      treinamento: 'NR-35 Trabalho em Altura',
      instrutor: 'Instrutor SENAI',
      dataAgendada: '18/03/2026',
      vagas: '8 / 10',
      status: 'Confirmada',
    },
    {
      turma: 'REC-2026-03',
      treinamento: 'NR-11 Operação de Empilhadeira',
      instrutor: 'Instrutor SENAI',
      dataAgendada: '02/04/2026',
      vagas: '5 / 8',
      status: 'Planejada',
    },
    {
      turma: 'REC-2026-04',
      treinamento: 'NR-06 Uso Adequado de EPIs',
      instrutor: 'Téc. Seg. Marcio',
      dataAgendada: '15/04/2026',
      vagas: '20 / 25',
      status: 'Planejada',
    },
    {
      turma: 'REC-2026-05',
      treinamento: 'Boas Práticas de Manipulação',
      instrutor: 'Nutricionista Fabiana',
      dataAgendada: '28/04/2026',
      vagas: '14 / 20',
      status: 'Planejada',
    },
  ];

  matrizCruzada: MatrizCruzadaItem[] = [
    {
      colaborador: 'Carlos Eduardo Silva',
      cargo: 'Operador de Empilhadeira',
      nr06: 'OK',
      nr11: 'OK',
      nr12: 'N/A',
      nr17: 'N/A',
      nr35: 'N/A',
    },
    {
      colaborador: 'Maria Joana Oliveira',
      cargo: 'Açougueira',
      nr06: 'OK',
      nr11: 'N/A',
      nr12: 'Vencido',
      nr17: 'N/A',
      nr35: 'N/A',
    },
    {
      colaborador: 'Roberto Alves',
      cargo: 'Operador de Caixa',
      nr06: 'OK',
      nr11: 'N/A',
      nr12: 'N/A',
      nr17: 'OK',
      nr35: 'N/A',
    },
    {
      colaborador: 'Ana Paula Souza',
      cargo: 'Repositora',
      nr06: 'OK',
      nr11: 'N/A',
      nr12: 'N/A',
      nr17: 'N/A',
      nr35: 'Alerta',
    },
    {
      colaborador: 'Fernando Costa',
      cargo: 'Padeiro',
      nr06: 'OK',
      nr11: 'N/A',
      nr12: 'OK',
      nr17: 'N/A',
      nr35: 'N/A',
    },
    {
      colaborador: 'Lucas Fontes',
      cargo: 'Operador de Empilhadeira',
      nr06: 'OK',
      nr11: 'Alerta',
      nr12: 'N/A',
      nr17: 'N/A',
      nr35: 'N/A',
    },
    {
      colaborador: 'Juliana Mendes',
      cargo: 'Operadora de Caixa',
      nr06: 'OK',
      nr11: 'N/A',
      nr12: 'N/A',
      nr17: 'OK',
      nr35: 'N/A',
    },
  ];

  selecionarCard(card: string): void {
    this.cardSelecionado = card;
  }

  setModoVisualizacao(modo: 'colaborador' | 'lista'): void {
    this.modoVisualizacao = modo;
  }

  abrirModalCertificacao(): void {
    this.mostrarModalCertificacao = true;
  }

  fecharModalCertificacao(): void {
    this.mostrarModalCertificacao = false;
  }

  abrirModalReciclagem(): void {
    this.mostrarModalReciclagem = true;
  }

  fecharModalReciclagem(): void {
    this.mostrarModalReciclagem = false;
  }

  salvarVinculoCertificacao(): void {
    this.fecharModalCertificacao();
  }

  salvarVinculoReciclagem(): void {
    this.fecharModalReciclagem();
  }

  abrirModalEdicaoGeral(item: any): void {
    this.itemOriginalReferencia = item;
    this.itemEmEdicao = { ...item };
    this.mostrarModalEdicaoGeral = true;
  }

  fecharModalEdicaoGeral(): void {
    this.mostrarModalEdicaoGeral = false;
    this.itemOriginalReferencia = null;
    this.itemEmEdicao = null;
  }

  salvarEdicaoGeral(): void {
    if (!this.itemEmEdicao) return;

    if (this.cardSelecionado === 'Visão Geral') {
      Object.assign(this.itemOriginalReferencia, this.itemEmEdicao);
      this.toast.success('Matriz atualizada com sucesso!');
      this.fecharModalEdicaoGeral();
      return;
    }

    if (this.itemEmEdicao.colaborador) {
      const colaboradorStr = String(this.itemEmEdicao.colaborador).trim();
      const existe = this.listaColaboradoresCadastrados.some(
        (c) => c.toLowerCase() === colaboradorStr.toLowerCase(),
      );
      if (!existe) {
        this.toast.error(`Colaborador "${colaboradorStr}" não está cadastrado no sistema.`);
        return;
      }
    }

    if (this.itemEmEdicao.cargo) {
      const cargoStr = String(this.itemEmEdicao.cargo).trim();
      const existe = this.listaCargosCadastrados.some(
        (c) => c.toLowerCase() === cargoStr.toLowerCase(),
      );
      if (!existe) {
        this.toast.error(`Cargo "${cargoStr}" não está cadastrado no sistema.`);
        return;
      }
    }

    const treinaNome = this.itemEmEdicao.treinamento || this.itemEmEdicao.nome;
    if (treinaNome) {
      const treinaStr = String(treinaNome).trim();
      const existe = this.listaTreinamentosCadastrados.some(
        (t) => t.toLowerCase() === treinaStr.toLowerCase(),
      );
      if (!existe) {
        this.toast.error(`Treinamento "${treinaStr}" não está cadastrado no sistema.`);
        return;
      }
    }

    if (this.itemEmEdicao.setor) {
      const setorStr = String(this.itemEmEdicao.setor).trim();
      const existe = this.listaSetoresCadastrados.some(
        (s) => s.toLowerCase() === setorStr.toLowerCase(),
      );
      if (!existe) {
        this.toast.error(`Setor "${setorStr}" não está cadastrado no sistema.`);
        return;
      }
    }

    Object.assign(this.itemOriginalReferencia, this.itemEmEdicao);
    this.toast.success('Registro atualizado com sucesso!');
    this.fecharModalEdicaoGeral();
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

  exportarMatriz(): void {
    const linhas = [
      'Colaborador,Cargo,NR-06,NR-11,NR-12,NR-17,NR-35',
      ...this.matrizCruzada.map(
        (m) =>
          `"${m.colaborador}","${m.cargo}","${m.nr06}","${m.nr11}","${m.nr12}","${m.nr17}","${m.nr35}"`,
      ),
    ];
    const blob = new Blob([linhas.join('\n')], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `matriz-conformidade-treinamentos-${new Date().toISOString().slice(0, 10)}.csv`;
    link.click();
    URL.revokeObjectURL(url);
  }
}
