export interface TreinamentoRequest {
  codigo: string;
  nome: string;
  classificacao: string;
  nr: string | null;
  cargaHoraria: string;
  validadeMeses: number | null;
  status: 'Ativo' | 'Inativo';
}
export interface Treinamento extends TreinamentoRequest {
  id: number;
}
