export type StatusVinculo = 'Concluído' | 'Em Andamento' | 'Pendente';
export type StatusCargo = 'Ativo' | 'Inativo';
export type StatusTurmaReciclagem = 'Agendada' | 'Concluída' | 'Cancelada';
export type StatusCertificacao = 'Ativa' | 'Alerta' | 'Vencida';

export interface VinculoRequest {
  colaboradorId: number;
  treinamentoId: number;
  dataConclusao: string | null;
  status: StatusVinculo;
}

export interface VinculoTreinamento extends VinculoRequest {
  id: number;
  colaborador: string;
  cargo: string;
  treinamento: string;
  validade: string | null;
}

export interface CertificacaoRequest {
  colaboradorId: number;
  treinamentoId: number;
  instituicao: string;
  cargaHoraria: string;
  emitidaEm: string;
  validade: string;
  arquivoUrl: string | null;
}

export interface Certificacao extends CertificacaoRequest {
  id: number;
  colaborador: string;
  cargo: string;
  treinamento: string;
  status: StatusCertificacao;
}

export interface CargoRequest {
  nome: string;
  setor: string;
  status: StatusCargo;
}

export interface Cargo extends CargoRequest {
  id: number;
}

export interface CargoTreinamentoItem {
  id?: number;
  treinamentoId: number;
  treinamento: string;
  nr?: string | null;
  obrigatorio: boolean;
}

export interface LntCargo {
  id: number;
  cargo: string;
  setor: string;
  status: string;
  treinamentos: CargoTreinamentoItem[];
}

export interface LntColaborador {
  colaboradorId: number;
  colaborador: string;
  cargo: string;
  setor: string;
  treinamentosPendentes: string[];
  status: 'Conforme' | 'Pendente';
}

export interface TurmaReciclagemRequest {
  treinamentoId: number;
  instrutor: string;
  dataAgendada: string;
  vagas: number;
  status: StatusTurmaReciclagem;
}

export interface TurmaReciclagem extends TurmaReciclagemRequest {
  id: number;
  treinamento: string;
}

export interface ReciclagemDerivada {
  colaboradorId: number;
  colaborador: string;
  cargo: string;
  treinamentoId: number;
  treinamento: string;
  prazoMaximo: string;
  diasRestantes: number;
  status: string;
}
