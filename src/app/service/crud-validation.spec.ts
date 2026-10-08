import { validarColaborador, validarTreinamento, validarEpi } from './crud-validation';
const c = {
  matricula: '001',
  nome: 'Pessoa',
  cpf: '123.456.789-00',
  email: 'p@a.com',
  cargo: 'Cargo',
  setor: 'Setor',
  status: 'Ativo' as const,
};
const t = {
  codigo: 'T1',
  nome: 'Curso',
  classificacao: 'Geral',
  nr: null,
  cargaHoraria: '4h',
  validadeMeses: null,
  status: 'Ativo' as const,
};
const e = {
  descricao: 'Luva',
  ca: '000123',
  inclusao: '2026-10-08',
  validade: '2027-10-08',
  quantidade: 0,
};
describe('Validação alinhada ao contrato e limites SQL', () => {
  it('aceita contratos válidos e zero/opcionais nulos', () => {
    expect(validarColaborador(c)).toBe(true);
    expect(validarTreinamento(t)).toBe(true);
    expect(validarEpi(e)).toBe(true);
    expect(validarTreinamento({ ...t, validadeMeses: 0 })).toBe(true);
  });
  it('rejeita campos brancos, tamanhos excedidos, CPF/email/status inválidos', () => {
    for (const d of [
      { ...c, nome: ' ' },
      { ...c, matricula: 'x'.repeat(31) },
      { ...c, email: 'invalido' },
      { ...c, cpf: '123' },
      { ...c, status: 'Outro' as any },
    ])
      expect(validarColaborador(d)).toBe(false);
  });
  it('rejeita validade fracionária, negativa ou acima do INTEGER e status inválido', () => {
    for (const d of [
      { ...t, codigo: '' },
      { ...t, nr: 'x'.repeat(61) },
      { ...t, validadeMeses: 0.5 },
      { ...t, validadeMeses: -1 },
      { ...t, validadeMeses: 2147483648 },
      { ...t, status: 'Obrigatório' as any },
    ])
      expect(validarTreinamento(d)).toBe(false);
  });
  it('rejeita CA excedido, quantidade fora do INTEGER e datas não ISO/impossíveis', () => {
    for (const d of [
      { ...e, ca: 'x'.repeat(31) },
      { ...e, quantidade: -1 },
      { ...e, quantidade: 1.5 },
      { ...e, quantidade: 2147483648 },
      { ...e, inclusao: '08/10/2026' },
      { ...e, validade: '2027-02-30' },
    ])
      expect(validarEpi(d)).toBe(false);
  });
});
