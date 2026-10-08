import { ColaboradorRequest } from '../models/colaborador.model';
import { TreinamentoRequest } from '../models/treinamento.model';
import { EpiRequest } from './epis.service';
function texto(value: string | null, max: number, optional = false): boolean {
  return (
    (optional && (value === null || value === '')) ||
    (typeof value === 'string' && !!value.trim() && value.length <= max)
  );
}
function inteiro(value: number): boolean {
  return Number.isInteger(value) && value >= 0 && value <= 2147483647;
}
function dataIso(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const date = new Date(value + 'T00:00:00Z');
  return !Number.isNaN(date.getTime()) && date.toISOString().slice(0, 10) === value;
}
export function validarColaborador(d: ColaboradorRequest): boolean {
  return (
    texto(d.matricula, 30) &&
    texto(d.nome, 150) &&
    texto(d.cpf, 14) &&
    d.cpf.replace(/\D/g, '').length === 11 &&
    texto(d.email, 180) &&
    /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(d.email.trim()) &&
    texto(d.cargo, 120) &&
    texto(d.setor, 120) &&
    ['Ativo', 'Inativo', 'Afastado'].includes(d.status)
  );
}
export function validarTreinamento(d: TreinamentoRequest): boolean {
  return (
    texto(d.codigo, 30) &&
    texto(d.nome, 180) &&
    texto(d.classificacao, 60) &&
    texto(d.nr, 60, true) &&
    texto(d.cargaHoraria, 30) &&
    (d.validadeMeses === null || inteiro(d.validadeMeses)) &&
    ['Ativo', 'Inativo'].includes(d.status)
  );
}
export function validarEpi(d: EpiRequest): boolean {
  return (
    texto(d.descricao, 180) &&
    texto(d.ca, 30) &&
    inteiro(d.quantidade) &&
    dataIso(d.inclusao) &&
    dataIso(d.validade)
  );
}
