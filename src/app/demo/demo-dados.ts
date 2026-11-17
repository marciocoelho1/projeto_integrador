import type { Colaborador } from '../models/colaborador.model';
import type { Treinamento } from '../models/treinamento.model';
import type {
  Cargo,
  Certificacao,
  LntCargo,
  LntColaborador,
  ReciclagemDerivada,
  TurmaReciclagem,
  VinculoTreinamento,
} from '../models/treinamento-avancado.model';
import type { Chamado } from '../service/chamado.service';
import type { Epi, EntregaEpi } from '../service/epis.service';
import type { DashboardIndicadores } from '../service/dashboard.service';
import type { GrupoApi, ModuloApi, UsuarioApi } from '../service/acesso.service';

/**
 * Estado do "banco de dados" do modo demonstração: fica só na memória do navegador.
 * Recarregar a página devolve os dados originais; incluir, editar e excluir funcionam
 * durante a sessão.
 */

/** Log de auditoria como a API devolve (o serviço da tela usa uma versão reduzida). */
export interface LogDemo {
  id: number;
  dataHora: string;
  usuarioId: number | null;
  usuario: string;
  modulo: string;
  acao: 'CRIACAO' | 'EDICAO' | 'EXCLUSAO' | 'ACESSO' | 'ALERTA';
  descricao: string;
  metodo: string;
  caminho: string;
  statusHttp: number;
}

export interface ParametroDemo {
  chave: string;
  valor: string;
  descricao: string;
}

export interface RegraAlertaDemo {
  codigo: string;
  nomeRegra: string;
  descricaoRegra: string;
  ativa: boolean;
}

export interface RedefinicaoDemo {
  id: number;
  usuario: string;
  login: string;
  token: string;
  criadoEm: string;
  expiraEm: string;
}

export interface EstadoDemo {
  colaboradores: Colaborador[];
  treinamentos: Treinamento[];
  epis: Epi[];
  entregasEpis: Array<
    Omit<EntregaEpi, 'colaborador' | 'matricula' | 'epi' | 'ca'> & { caNoAto: string }
  >;
  vinculos: Array<Omit<VinculoTreinamento, 'colaborador' | 'cargo' | 'treinamento' | 'validade'>>;
  certificacoes: Array<Omit<Certificacao, 'colaborador' | 'cargo' | 'treinamento' | 'status'>>;
  cargos: Cargo[];
  cargoTreinamentos: Array<{
    id: number;
    cargoId: number;
    treinamentoId: number;
    obrigatorio: boolean;
  }>;
  turmasReciclagem: Array<Omit<TurmaReciclagem, 'treinamento'>>;
  usuarios: UsuarioApi[];
  grupos: GrupoApi[];
  modulos: ModuloApi[];
  chamados: Chamado[];
  logs: LogDemo[];
  parametros: ParametroDemo[];
  regrasAlerta: RegraAlertaDemo[];
  redefinicoes: RedefinicaoDemo[];
}

/* =======================================================
   Datas
   ======================================================= */

function doisDigitos(valor: number): string {
  return String(valor).padStart(2, '0');
}

function emIso(data: Date): string {
  return `${data.getFullYear()}-${doisDigitos(data.getMonth() + 1)}-${doisDigitos(data.getDate())}`;
}

export function hojeIso(): string {
  return emIso(new Date());
}

export function diasAtras(dias: number): string {
  const data = new Date();
  data.setDate(data.getDate() - dias);

  return emIso(data);
}

export function diasFrente(dias: number): string {
  return diasAtras(-dias);
}

export function agoraIso(): string {
  return new Date().toISOString();
}

export function somarMeses(iso: string | null, meses: number | null): string | null {
  if (!iso || !meses) return null;

  const data = new Date(`${iso}T00:00:00`);
  data.setMonth(data.getMonth() + meses);

  return emIso(data);
}

function instante(dias: number, hora: string): string {
  return `${diasAtras(dias)}T${hora}:00-03:00`;
}

/* =======================================================
   Dados de exemplo
   ======================================================= */

const SETORES: Array<[string, number]> = [
  ['Frente de Loja', 5],
  ['Mercearia', 4],
  ['Açougue', 3],
  ['Depósito', 2],
  ['Administrativo', 2],
];

const PESSOAS = [
  'Ana Ribeiro',
  'Bruno Salles',
  'Carla Mendes',
  'Diego Alves',
  'Elisa Prado',
  'Fábio Nunes',
  'Gabriela Rosa',
  'Heitor Lima',
  'Isabela Cruz',
  'João Pedro Alves',
  'Karina Lopes',
  'Lucas Faria',
  'Marina Costa',
  'Nelson Braga',
  'Olívia Sá',
  'Paulo Reis',
];

const CARGOS_POR_SETOR: Record<string, string> = {
  'Frente de Loja': 'Operador(a) de Caixa',
  Mercearia: 'Repositor(a)',
  Açougue: 'Açougueiro(a)',
  Depósito: 'Auxiliar de Logística',
  Administrativo: 'Assistente Administrativo',
};

function criarColaboradores(): Colaborador[] {
  const colaboradores: Colaborador[] = [];

  for (const [setor, quantidade] of SETORES) {
    for (let indice = 0; indice < quantidade; indice++) {
      const numero = colaboradores.length + 1;
      const nome = PESSOAS[numero - 1];

      colaboradores.push({
        id: numero,
        matricula: String(numero).padStart(3, '0'),
        nome,
        cpf: `${String(numero).padStart(3, '0')}.${String(numero * 7).padStart(3, '0')}.${String(numero * 13).padStart(3, '0')}-0${numero % 10}`,
        email: `${nome.split(' ')[0].toLowerCase()}@essenza.com.br`,
        cargo: CARGOS_POR_SETOR[setor] ?? 'Auxiliar',
        setor,
        status: numero <= 12 ? 'Ativo' : numero === 13 ? 'Afastado' : 'Inativo',
      });
    }
  }

  return colaboradores;
}

function criarTreinamentos(): Treinamento[] {
  return [
    {
      id: 1,
      codigo: 'NR-35',
      nome: 'Trabalho em Altura',
      classificacao: 'NR',
      nr: 'NR-35',
      cargaHoraria: '8h',
      validadeMeses: 24,
      status: 'Ativo',
    },
    {
      id: 2,
      codigo: 'NR-06',
      nome: 'Uso e Conservação de EPI',
      classificacao: 'NR',
      nr: 'NR-06',
      cargaHoraria: '4h',
      validadeMeses: 12,
      status: 'Ativo',
    },
    {
      id: 3,
      codigo: 'NR-10',
      nome: 'Segurança em Instalações Elétricas',
      classificacao: 'NR',
      nr: 'NR-10',
      cargaHoraria: '40h',
      validadeMeses: 24,
      status: 'Ativo',
    },
    {
      id: 4,
      codigo: 'NR-11',
      nome: 'Operação de Empilhadeira',
      classificacao: 'NR',
      nr: 'NR-11',
      cargaHoraria: '16h',
      validadeMeses: 12,
      status: 'Ativo',
    },
    {
      id: 5,
      codigo: 'INT-01',
      nome: 'Integração de Novos Colaboradores',
      classificacao: 'Interno',
      nr: null,
      cargaHoraria: '4h',
      validadeMeses: null,
      status: 'Ativo',
    },
    {
      id: 6,
      codigo: 'INT-02',
      nome: 'Boas Práticas de Manipulação',
      classificacao: 'Interno',
      nr: null,
      cargaHoraria: '8h',
      validadeMeses: 12,
      status: 'Ativo',
    },
    {
      id: 7,
      codigo: 'NR-23',
      nome: 'Prevenção e Combate a Incêndio',
      classificacao: 'NR',
      nr: 'NR-23',
      cargaHoraria: '8h',
      validadeMeses: 24,
      status: 'Ativo',
    },
    {
      id: 8,
      codigo: 'INT-03',
      nome: 'Primeiros Socorros',
      classificacao: 'Interno',
      nr: null,
      cargaHoraria: '6h',
      validadeMeses: 24,
      status: 'Inativo',
    },
  ];
}

function criarEpis(): Epi[] {
  return [
    {
      id: 1,
      descricao: 'Protetor Auricular',
      ca: '12345',
      inclusao: diasAtras(400),
      validade: diasAtras(20),
      quantidade: 2,
    },
    {
      id: 2,
      descricao: 'Luva Nitrílica',
      ca: '39012',
      inclusao: diasAtras(300),
      validade: diasFrente(200),
      quantidade: 3,
    },
    {
      id: 3,
      descricao: 'Cinto Paraquedista',
      ca: '30498',
      inclusao: diasAtras(200),
      validade: diasFrente(40),
      quantidade: 4,
    },
    {
      id: 4,
      descricao: 'Botina de Segurança',
      ca: '215',
      inclusao: diasAtras(150),
      validade: diasFrente(300),
      quantidade: 46,
    },
    {
      id: 5,
      descricao: 'Capacete de Segurança',
      ca: '777',
      inclusao: diasAtras(100),
      validade: diasFrente(400),
      quantidade: 18,
    },
    {
      id: 6,
      descricao: 'Óculos de Segurança',
      ca: '555',
      inclusao: diasAtras(90),
      validade: diasFrente(15),
      quantidade: 24,
    },
    {
      id: 7,
      descricao: 'Avental Térmico',
      ca: '88123',
      inclusao: diasAtras(60),
      validade: diasFrente(120),
      quantidade: 5,
    },
    {
      id: 8,
      descricao: 'Máscara PFF2',
      ca: '91110',
      inclusao: diasAtras(30),
      validade: diasFrente(500),
      quantidade: 60,
    },
  ];
}

function criarEntregas(colaboradores: Colaborador[], epis: Epi[]): EstadoDemo['entregasEpis'] {
  const entregas: EstadoDemo['entregasEpis'] = [];
  const quantidadesPorMes = [12, 18, 9, 22, 15, 9];
  let id = 0;

  quantidadesPorMes.forEach((quantidade, indiceMes) => {
    const mesesAtras = 5 - indiceMes;

    for (let item = 0; item < quantidade; item++) {
      id += 1;
      const colaborador = colaboradores[(id * 3) % colaboradores.length];
      const epi = epis[(id * 5) % epis.length];
      const dias = mesesAtras * 30 + (item % 12) + 1;

      entregas.push({
        id,
        colaboradorId: colaborador.id,
        epiId: epi.id,
        quantidade: 1 + (id % 2),
        dataEntrega: diasAtras(dias),
        assinatura: id % 5 === 0 ? '' : colaborador.nome,
        registradoEm: instante(dias, '14:20'),
        caNoAto: epi.ca,
      });
    }
  });

  return entregas;
}

function criarVinculos(): EstadoDemo['vinculos'] {
  // [colaboradorId, treinamentoId, concluído, diasParaVencer (negativo = vencido; null = sem validade)]
  const plano: Array<[number, number, boolean, number | null]> = [
    [1, 1, true, 320],
    [2, 1, true, 180],
    [3, 1, true, -45],
    [4, 1, true, 210],
    [5, 2, true, 90],
    [6, 2, true, -12],
    [7, 2, true, 45],
    [8, 2, true, 300],
    [9, 3, true, 150],
    [10, 3, true, -60],
    [11, 3, true, 25],
    [12, 3, true, 400],
    [13, 4, true, -8],
    [14, 4, true, 60],
    [15, 4, true, 240],
    [16, 4, true, 120],
    [5, 5, true, null],
    [8, 6, true, 20],
    [11, 7, true, -30],
    [2, 6, true, null],
    [6, 5, true, null],
    [9, 7, false, null],
    [3, 2, false, null],
    [7, 3, false, null],
  ];

  return plano.map(([colaboradorId, treinamentoId, concluido, dias], indice) => ({
    id: indice + 1,
    colaboradorId,
    treinamentoId,
    // A conclusão é posicionada de forma que a validade caia em `dias` (negativo = já venceu).
    dataConclusao: concluido ? diasAtras((dias ?? 0) + 365) : null,
    status: concluido ? ('Concluído' as const) : ('Pendente' as const),
  }));
}

function criarCertificacoes(): EstadoDemo['certificacoes'] {
  const plano: Array<[number, number, number]> = [
    [1, 1, 400],
    [2, 1, 150],
    [3, 2, -20],
    [4, 3, 600],
    [5, 4, 90],
    [6, 1, 30],
    [7, 2, 700],
    [8, 3, -5],
    [9, 4, 250],
    [10, 1, 45],
    [11, 2, 500],
    [12, 3, -75],
  ];

  return plano.map(([colaboradorId, treinamentoId, dias], indice) => ({
    id: indice + 1,
    colaboradorId,
    treinamentoId,
    instituicao: indice % 2 === 0 ? 'Senac' : 'SESI',
    cargaHoraria: indice % 3 === 0 ? '8h' : '4h',
    emitidaEm: diasAtras(400 - indice * 5),
    validade: diasFrente(dias),
    arquivoUrl: null,
  }));
}

function criarChamados(): Chamado[] {
  const chamados: Chamado[] = [
    {
      id: 1,
      tipo: 'Ajuda',
      descricao: 'Como registro a reciclagem de um colaborador?',
      usuarioId: 2,
      solicitante: 'Ana Ribeiro',
      status: 'Em andamento',
      abertoEm: instante(2, '09:12'),
      concluidoEm: null,
    },
    {
      id: 2,
      tipo: 'Erro',
      descricao: 'A importação da planilha de EPIs não aceita a coluna de CA.',
      usuarioId: 3,
      solicitante: 'Bruno Salles',
      status: 'Em andamento',
      abertoEm: instante(1, '11:40'),
      concluidoEm: null,
    },
    {
      id: 3,
      tipo: 'Ajuda',
      descricao: 'Dúvida sobre EPI com CA vencido no estoque.',
      usuarioId: 4,
      solicitante: 'Carla Mendes',
      status: 'Em andamento',
      abertoEm: instante(0, '08:05'),
      concluidoEm: null,
    },
  ];

  for (let indice = 0; indice < 5; indice++) {
    chamados.push({
      id: 4 + indice,
      tipo: indice % 2 === 0 ? 'Ajuda' : 'Erro',
      descricao: `Chamado concluído ${indice + 1} sobre o uso do sistema.`,
      usuarioId: 1,
      solicitante: PESSOAS[indice + 4],
      status: 'Concluída',
      abertoEm: instante(10 + indice, '10:00'),
      concluidoEm: instante(3, '16:30'),
    });
  }

  return chamados;
}

function criarLogs(): LogDemo[] {
  return [
    {
      id: 6,
      dataHora: instante(0, '19:12'),
      usuarioId: 1,
      usuario: 'Administrador',
      modulo: 'epis',
      acao: 'CRIACAO',
      descricao: 'Entrega de EPI registrada para Ana Ribeiro.',
      metodo: 'POST',
      caminho: '/api/entregas-epis',
      statusHttp: 201,
    },
    {
      id: 5,
      dataHora: instante(1, '18:40'),
      usuarioId: 1,
      usuario: 'Administrador',
      modulo: 'treinamentos',
      acao: 'CRIACAO',
      descricao: 'Certificação NR-10 vinculada a Marina Costa.',
      metodo: 'POST',
      caminho: '/api/certificacoes',
      statusHttp: 201,
    },
    {
      id: 4,
      dataHora: instante(2, '16:05'),
      usuarioId: 1,
      usuario: 'Administrador',
      modulo: 'colaboradores',
      acao: 'EDICAO',
      descricao: 'E-mail do colaborador atualizado.',
      metodo: 'PUT',
      caminho: '/api/colaboradores/4',
      statusHttp: 200,
    },
    {
      id: 3,
      dataHora: instante(2, '11:27'),
      usuarioId: 4,
      usuario: 'Carla Mendes',
      modulo: 'ajuda-suporte',
      acao: 'ALERTA',
      descricao: 'Chamado de suporte aberto por colaborador.',
      metodo: 'POST',
      caminho: '/api/chamados',
      statusHttp: 201,
    },
    {
      id: 2,
      dataHora: instante(3, '14:02'),
      usuarioId: 1,
      usuario: 'Administrador',
      modulo: 'epis',
      acao: 'EDICAO',
      descricao: 'Estoque do EPI Botina de Segurança ajustado.',
      metodo: 'PUT',
      caminho: '/api/epis/4',
      statusHttp: 200,
    },
    {
      id: 1,
      dataHora: instante(4, '08:15'),
      usuarioId: 1,
      usuario: 'Administrador',
      modulo: 'auth',
      acao: 'ACESSO',
      descricao: 'Sessão iniciada no sistema.',
      metodo: 'POST',
      caminho: '/api/auth/login',
      statusHttp: 200,
    },
  ];
}

function criarModulos(): ModuloApi[] {
  return [
    { chave: 'sgst_dashboard', titulo: 'Dashboard', detalhe: 'Indicadores gerais de SST' },
    { chave: 'sgst_colaboradores', titulo: 'Colaboradores', detalhe: 'Quadro de colaboradores' },
    { chave: 'sgst_epis', titulo: 'EPIs', detalhe: 'Estoque, CA e entregas' },
    {
      chave: 'sgst_treinamentos',
      titulo: 'Matriz de Treinamentos',
      detalhe: 'Catálogo, vínculos e certificações',
    },
    { chave: 'sgst_relatorios', titulo: 'Relatórios', detalhe: 'Exportação em CSV' },
    { chave: 'sgst_config', titulo: 'Configurações', detalhe: 'Usuários, permissões e auditoria' },
  ];
}

function criarGrupos(): GrupoApi[] {
  return [
    {
      id: 1,
      nomenclatura: 'Administrador TST',
      finalidade: 'Acesso irrestrito para técnicos e engenheiros de segurança do trabalho.',
      modulos: [
        'sgst_dashboard',
        'sgst_colaboradores',
        'sgst_epis',
        'sgst_treinamentos',
        'sgst_relatorios',
        'sgst_config',
      ],
    },
    {
      id: 2,
      nomenclatura: 'Colaborador',
      finalidade: 'Consulta dos próprios treinamentos, certificações e EPIs.',
      modulos: ['sgst_dashboard', 'sgst_epis', 'sgst_relatorios'],
    },
  ];
}

function criarUsuarios(): UsuarioApi[] {
  return [
    {
      id: 1,
      nomeCompleto: 'Administrador do Sistema',
      login: 'admin',
      email: 'admin@essenza.com.br',
      cpf: '000.000.000-01',
      grupoId: 1,
      grupo: 'Administrador TST',
      status: 'Ativo',
      modulos: [
        'sgst_dashboard',
        'sgst_colaboradores',
        'sgst_epis',
        'sgst_treinamentos',
        'sgst_relatorios',
        'sgst_config',
      ],
      criadoEm: instante(120, '09:00'),
    },
    {
      id: 2,
      nomeCompleto: 'Ana Ribeiro',
      login: 'ana.ribeiro',
      email: 'ana@essenza.com.br',
      cpf: '111.111.111-02',
      grupoId: 2,
      grupo: 'Colaborador',
      status: 'Ativo',
      modulos: ['sgst_dashboard', 'sgst_epis', 'sgst_relatorios'],
      criadoEm: instante(110, '09:10'),
    },
    {
      id: 3,
      nomeCompleto: 'Bruno Salles',
      login: 'bruno.salles',
      email: 'bruno@essenza.com.br',
      cpf: '222.222.222-03',
      grupoId: 2,
      grupo: 'Colaborador',
      status: 'Ativo',
      modulos: ['sgst_dashboard', 'sgst_epis'],
      criadoEm: instante(100, '10:20'),
    },
    {
      id: 4,
      nomeCompleto: 'Carla Mendes',
      login: 'colaborador',
      email: 'carla@essenza.com.br',
      cpf: '333.333.333-04',
      grupoId: 2,
      grupo: 'Colaborador',
      status: 'Ativo',
      modulos: ['sgst_dashboard', 'sgst_epis', 'sgst_relatorios'],
      criadoEm: instante(90, '11:05'),
    },
    {
      id: 5,
      nomeCompleto: 'Diego Alves',
      login: 'diego.alves',
      email: 'diego@essenza.com.br',
      cpf: '444.444.444-05',
      grupoId: 2,
      grupo: 'Colaborador',
      status: 'Inativo',
      modulos: ['sgst_dashboard'],
      criadoEm: instante(60, '14:40'),
    },
  ];
}

function criarCargos(): Cargo[] {
  return [
    { id: 1, nome: 'Operador(a) de Caixa', setor: 'Frente de Loja', status: 'Ativo' },
    { id: 2, nome: 'Repositor(a)', setor: 'Mercearia', status: 'Ativo' },
    { id: 3, nome: 'Açougueiro(a)', setor: 'Açougue', status: 'Ativo' },
    { id: 4, nome: 'Auxiliar de Logística', setor: 'Depósito', status: 'Ativo' },
    { id: 5, nome: 'Assistente Administrativo', setor: 'Administrativo', status: 'Ativo' },
  ];
}

function criarCargoTreinamentos(): EstadoDemo['cargoTreinamentos'] {
  return [
    { id: 1, cargoId: 1, treinamentoId: 2, obrigatorio: true },
    { id: 2, cargoId: 1, treinamentoId: 5, obrigatorio: true },
    { id: 3, cargoId: 2, treinamentoId: 2, obrigatorio: true },
    { id: 4, cargoId: 2, treinamentoId: 6, obrigatorio: false },
    { id: 5, cargoId: 3, treinamentoId: 2, obrigatorio: true },
    { id: 6, cargoId: 3, treinamentoId: 6, obrigatorio: true },
    { id: 7, cargoId: 4, treinamentoId: 4, obrigatorio: true },
    { id: 8, cargoId: 4, treinamentoId: 2, obrigatorio: true },
    { id: 9, cargoId: 5, treinamentoId: 5, obrigatorio: true },
    { id: 10, cargoId: 5, treinamentoId: 7, obrigatorio: false },
  ];
}

function criarTurmas(): EstadoDemo['turmasReciclagem'] {
  return [
    {
      id: 1,
      treinamentoId: 2,
      instrutor: 'Fernanda Lima',
      dataAgendada: diasFrente(7),
      vagas: 12,
      status: 'Agendada',
    },
    {
      id: 2,
      treinamentoId: 1,
      instrutor: 'Rogério Pinto',
      dataAgendada: diasFrente(15),
      vagas: 8,
      status: 'Agendada',
    },
    {
      id: 3,
      treinamentoId: 7,
      instrutor: 'Brigada Interna',
      dataAgendada: diasAtras(20),
      vagas: 16,
      status: 'Concluída',
    },
    {
      id: 4,
      treinamentoId: 3,
      instrutor: 'Rogério Pinto',
      dataAgendada: diasFrente(30),
      vagas: 6,
      status: 'Cancelada',
    },
  ];
}

function criarParametros(): ParametroDemo[] {
  return [
    {
      chave: 'dias_alerta_vencimento',
      valor: '30',
      descricao: 'Janela, em dias, para avisar sobre CA e reciclagens a vencer.',
    },
    {
      chave: 'estoque_minimo_epi',
      valor: '5',
      descricao: 'Quantidade mínima de cada EPI no estoque.',
    },
    {
      chave: 'dias_alerta_certificacao',
      valor: '60',
      descricao: 'Janela, em dias, para avisar sobre certificações a vencer.',
    },
    {
      chave: 'limite_importacao_linhas',
      valor: '500',
      descricao: 'Máximo de linhas aceitas por lote de importação.',
    },
    {
      chave: 'exigir_assinatura_entrega',
      valor: 'true',
      descricao: 'Exige assinatura do colaborador ao registrar a entrega.',
    },
    {
      chave: 'empresa_nome',
      valor: 'Essenza Supermercados Ltda.',
      descricao: 'Razão social exibida no sistema.',
    },
  ];
}

function criarRegras(): RegraAlertaDemo[] {
  return [
    {
      codigo: 'EPI_CA_VENCIDO',
      nomeRegra: 'EPI com CA vencido',
      descricaoRegra: 'Avisa quando há unidades em estoque com CA fora da validade.',
      ativa: true,
    },
    {
      codigo: 'EPI_CA_A_VENCER',
      nomeRegra: 'EPI com CA a vencer',
      descricaoRegra: 'Avisa quando o CA vence dentro da janela configurada.',
      ativa: true,
    },
    {
      codigo: 'EPI_ESTOQUE_MINIMO',
      nomeRegra: 'Estoque mínimo de EPI',
      descricaoRegra: 'Avisa quando a quantidade fica no limite mínimo.',
      ativa: true,
    },
    {
      codigo: 'TREINAMENTO_VENCIDO',
      nomeRegra: 'Reciclagem vencida',
      descricaoRegra: 'Avisa sobre vínculos de treinamento com validade expirada.',
      ativa: true,
    },
    {
      codigo: 'CERTIFICACAO_A_VENCER',
      nomeRegra: 'Certificação a vencer',
      descricaoRegra: 'Avisa sobre certificações perto do vencimento.',
      ativa: false,
    },
    {
      codigo: 'CHAMADO_ABERTO',
      nomeRegra: 'Chamados abertos',
      descricaoRegra: 'Avisa quando existem chamados de suporte em andamento.',
      ativa: true,
    },
  ];
}

/** Estado inicial do modo demonstração. */
export function criarEstadoDemo(): EstadoDemo {
  const colaboradores = criarColaboradores();
  const treinamentos = criarTreinamentos();
  const epis = criarEpis();

  return {
    colaboradores,
    treinamentos,
    epis,
    entregasEpis: criarEntregas(colaboradores, epis),
    vinculos: criarVinculos(),
    certificacoes: criarCertificacoes(),
    cargos: criarCargos(),
    cargoTreinamentos: criarCargoTreinamentos(),
    turmasReciclagem: criarTurmas(),
    usuarios: criarUsuarios(),
    grupos: criarGrupos(),
    modulos: criarModulos(),
    chamados: criarChamados(),
    logs: criarLogs(),
    parametros: criarParametros(),
    regrasAlerta: criarRegras(),
    redefinicoes: [],
  };
}

/* =======================================================
   Campos derivados (os mesmos que o backend resolve nas consultas)
   ======================================================= */

export function serializarEntrega(
  estado: EstadoDemo,
  entrega: EstadoDemo['entregasEpis'][number],
): EntregaEpi {
  const colaborador = estado.colaboradores.find((item) => item.id === entrega.colaboradorId);
  const epi = estado.epis.find((item) => item.id === entrega.epiId);

  return {
    id: entrega.id,
    colaboradorId: entrega.colaboradorId,
    colaborador: colaborador?.nome ?? 'Colaborador removido',
    matricula: colaborador?.matricula ?? '-',
    epiId: entrega.epiId,
    epi: epi?.descricao ?? 'EPI removido',
    ca: entrega.caNoAto,
    quantidade: entrega.quantidade,
    dataEntrega: entrega.dataEntrega,
    assinatura: entrega.assinatura,
    registradoEm: entrega.registradoEm,
  };
}

export function serializarVinculo(
  estado: EstadoDemo,
  vinculo: EstadoDemo['vinculos'][number],
): VinculoTreinamento {
  const colaborador = estado.colaboradores.find((item) => item.id === vinculo.colaboradorId);
  const treinamento = estado.treinamentos.find((item) => item.id === vinculo.treinamentoId);

  return {
    ...vinculo,
    colaborador: colaborador?.nome ?? 'Colaborador removido',
    cargo: colaborador?.cargo ?? '-',
    treinamento: treinamento?.nome ?? 'Treinamento removido',
    validade: somarMeses(vinculo.dataConclusao, treinamento?.validadeMeses ?? null),
  };
}

/** Mesma regra do backend: vencida, em alerta (60 dias) ou ativa. */
export function statusCertificacao(
  validade: string,
  referencia = hojeIso(),
): Certificacao['status'] {
  if (validade < referencia) return 'Vencida';

  const dias = Math.round(
    (new Date(`${validade}T00:00:00`).getTime() - new Date(`${referencia}T00:00:00`).getTime()) /
      86400000,
  );

  return dias <= 60 ? 'Alerta' : 'Ativa';
}

export function serializarCertificacao(
  estado: EstadoDemo,
  certificacao: EstadoDemo['certificacoes'][number],
): Certificacao {
  const colaborador = estado.colaboradores.find((item) => item.id === certificacao.colaboradorId);
  const treinamento = estado.treinamentos.find((item) => item.id === certificacao.treinamentoId);

  return {
    ...certificacao,
    colaborador: colaborador?.nome ?? 'Colaborador removido',
    cargo: colaborador?.cargo ?? '-',
    treinamento: treinamento?.nome ?? 'Treinamento removido',
    status: statusCertificacao(certificacao.validade),
  };
}

export function serializarLnt(estado: EstadoDemo): LntCargo[] {
  return estado.cargos.map((cargo) => ({
    id: cargo.id,
    cargo: cargo.nome,
    setor: cargo.setor,
    status: cargo.status,
    treinamentos: estado.cargoTreinamentos
      .filter((item) => item.cargoId === cargo.id)
      .map((item) => {
        const treinamento = estado.treinamentos.find((atual) => atual.id === item.treinamentoId);

        return {
          id: item.id,
          treinamentoId: item.treinamentoId,
          treinamento: treinamento?.nome ?? 'Treinamento removido',
          nr: treinamento?.nr ?? null,
          obrigatorio: item.obrigatorio,
        };
      }),
  }));
}

export function serializarLntColaboradores(estado: EstadoDemo): LntColaborador[] {
  return estado.colaboradores.map((colaborador) => {
    const cargo = estado.cargos.find((item) => item.nome === colaborador.cargo);
    const exigidos = estado.cargoTreinamentos.filter(
      (item) => item.cargoId === cargo?.id && item.obrigatorio,
    );
    const pendentes = exigidos
      .filter(
        (item) =>
          !estado.vinculos.some(
            (vinculo) =>
              vinculo.colaboradorId === colaborador.id &&
              vinculo.treinamentoId === item.treinamentoId &&
              vinculo.status === 'Concluído' &&
              (somarMeses(
                vinculo.dataConclusao,
                estado.treinamentos.find((t) => t.id === item.treinamentoId)?.validadeMeses ?? null,
              ) ?? '') >= hojeIso(),
          ),
      )
      .map(
        (item) =>
          estado.treinamentos.find((t) => t.id === item.treinamentoId)?.nome ??
          'Treinamento removido',
      );

    return {
      colaboradorId: colaborador.id,
      colaborador: colaborador.nome,
      cargo: colaborador.cargo,
      setor: colaborador.setor,
      treinamentosPendentes: pendentes,
      status: pendentes.length === 0 ? 'Conforme' : 'Pendente',
    };
  });
}

/** Reciclagens derivadas da validade dos vínculos (mesma janela de 60 dias do backend). */
export function serializarReciclagens(estado: EstadoDemo): ReciclagemDerivada[] {
  const limite = diasFrente(60);

  return estado.vinculos
    .map((vinculo) => serializarVinculo(estado, vinculo))
    .filter((vinculo) => !!vinculo.validade && vinculo.validade <= limite)
    .map((vinculo) => {
      const colaborador = estado.colaboradores.find((item) => item.id === vinculo.colaboradorId);
      const prazoMaximo = vinculo.validade as string;
      const diasRestantes = Math.round(
        (new Date(`${prazoMaximo}T00:00:00`).getTime() -
          new Date(`${hojeIso()}T00:00:00`).getTime()) /
          86400000,
      );

      return {
        colaboradorId: vinculo.colaboradorId,
        colaborador: vinculo.colaborador,
        cargo: colaborador?.cargo ?? '-',
        treinamentoId: vinculo.treinamentoId,
        treinamento: vinculo.treinamento,
        prazoMaximo,
        diasRestantes,
        status: diasRestantes < 0 ? 'Vencida' : 'A vencer',
      };
    })
    .sort((a, b) => a.diasRestantes - b.diasRestantes);
}

/** Indicadores do dashboard: os mesmos cálculos do DashboardService. */
export function calcularIndicadores(estado: EstadoDemo): DashboardIndicadores {
  const hoje = hojeIso();
  const limite = diasFrente(30);

  const ativos = estado.colaboradores.filter((item) => item.status === 'Ativo').length;
  const inativos = estado.colaboradores.filter((item) => item.status === 'Inativo').length;
  const afastados = estado.colaboradores.filter((item) => item.status === 'Afastado').length;

  const certificacoes = estado.certificacoes.map((item) => serializarCertificacao(estado, item));
  const certificacoesVencidas = certificacoes.filter((item) => item.status === 'Vencida').length;
  const certificacoesAVencer = certificacoes.filter((item) => item.status === 'Alerta').length;
  const certificacoesAtivas = certificacoes.filter((item) => item.status === 'Ativa').length;

  const vencidos = estado.epis.filter((epi) => !!epi.validade && epi.validade < hoje);
  const aVencer = estado.epis.filter(
    (epi) => !!epi.validade && epi.validade >= hoje && epi.validade <= limite,
  );

  const vinculos = estado.vinculos.map((item) => serializarVinculo(estado, item));
  const vinculosConcluidos = vinculos.filter((item) => item.status === 'Concluído').length;
  const vinculosVencidos = vinculos.filter(
    (item) => !!item.validade && item.validade < hoje,
  ).length;
  const vinculosEmDia = Math.max(0, vinculosConcluidos - vinculosVencidos);
  const vinculosPendentes = Math.max(0, vinculos.length - vinculosConcluidos) + vinculosVencidos;

  const chamadosEmAndamento = estado.chamados.filter(
    (chamado) => chamado.status === 'Em andamento',
  ).length;

  const alertas: DashboardIndicadores['alertas'] = [];

  if (vencidos.length > 0) {
    alertas.push({
      tipo: 'EPI',
      mensagem: `${vencidos.reduce((soma, epi) => soma + epi.quantidade, 0)} unidade(s) de EPI com CA vencido no estoque.`,
      criticidade: 'alta',
    });
  }

  if (certificacoesVencidas > 0) {
    alertas.push({
      tipo: 'Certificação',
      mensagem: `${certificacoesVencidas} certificação(ões) de colaborador vencida(s).`,
      criticidade: 'alta',
    });
  }

  if (vinculosVencidos > 0) {
    alertas.push({
      tipo: 'Treinamento',
      mensagem: `${vinculosVencidos} treinamento(s) de colaborador com reciclagem vencida.`,
      criticidade: 'alta',
    });
  }

  if (aVencer.length > 0) {
    alertas.push({
      tipo: 'EPI',
      mensagem: `${aVencer.reduce((soma, epi) => soma + epi.quantidade, 0)} unidade(s) de EPI vencem nos próximos 30 dias.`,
      criticidade: 'media',
    });
  }

  if (certificacoesAVencer > 0) {
    alertas.push({
      tipo: 'Certificação',
      mensagem: `${certificacoesAVencer} certificação(ões) vencem em até 60 dias.`,
      criticidade: 'media',
    });
  }

  if (vinculosPendentes > 0) {
    alertas.push({
      tipo: 'Treinamento',
      mensagem: `${vinculosPendentes} treinamento(s) obrigatório(s) ainda pendente(s).`,
      criticidade: 'media',
    });
  }

  if (chamadosEmAndamento > 0) {
    alertas.push({
      tipo: 'Suporte',
      mensagem: `${chamadosEmAndamento} chamado(s) de suporte em andamento.`,
      criticidade: 'media',
    });
  }

  if (alertas.length === 0) {
    alertas.push({
      tipo: 'Geral',
      mensagem: 'Nenhuma pendência crítica no momento.',
      criticidade: 'baixa',
    });
  }

  return {
    colaboradores: { total: estado.colaboradores.length, ativos, inativos, afastados },
    certificacoes: {
      total: certificacoes.length,
      ativas: certificacoesAtivas,
      vencidas: certificacoesVencidas,
      vencendoEm30Dias: certificacoesAVencer,
    },
    epis: {
      emEstoque: estado.epis.reduce((soma, epi) => soma + epi.quantidade, 0),
      proximoVencimento: aVencer.reduce((soma, epi) => soma + epi.quantidade, 0),
      vencidos: vencidos.reduce((soma, epi) => soma + epi.quantidade, 0),
      entreguesUltimos30Dias: estado.entregasEpis
        .filter((entrega) => entrega.dataEntrega >= diasAtras(30))
        .reduce((soma, entrega) => soma + entrega.quantidade, 0),
      totalTipos: estado.epis.length,
    },
    treinamentos: {
      concluidos: vinculosConcluidos,
      pendentes: vinculosPendentes,
      vencidos: vinculosVencidos,
      total: vinculos.length,
      porcentagem: vinculos.length === 0 ? 0 : Math.round((vinculosEmDia * 100) / vinculos.length),
    },
    alertas,
    geradoEm: agoraIso(),
  };
}

/** Conteúdo dos relatórios em CSV, no mesmo formato Categoria/Métrica/Valor usado no backend. */
export function relatorioCsv(estado: EstadoDemo, nome: string): string | null {
  const linhas: string[] = [];
  const indicadores = calcularIndicadores(estado);

  if (nome === 'dashboard') {
    linhas.push('Categoria;Métrica;Valor');
    linhas.push(`Colaboradores;Total;${indicadores.colaboradores.total}`);
    linhas.push(`Colaboradores;Ativos;${indicadores.colaboradores.ativos}`);
    linhas.push(`Colaboradores;Afastados;${indicadores.colaboradores.afastados}`);
    linhas.push(`Colaboradores;Inativos;${indicadores.colaboradores.inativos}`);
    linhas.push(`Certificações;Ativas;${indicadores.certificacoes.ativas}`);
    linhas.push(`Certificações;Vencidas;${indicadores.certificacoes.vencidas}`);
    linhas.push(`EPIs;Unidades em estoque;${indicadores.epis.emEstoque}`);
    linhas.push(`EPIs;Unidades vencidas;${indicadores.epis.vencidos}`);
    linhas.push(`Treinamentos;Vínculos;${indicadores.treinamentos.total}`);
    linhas.push(`Treinamentos;Concluídos;${indicadores.treinamentos.concluidos}`);
    linhas.push(`Treinamentos;Percentual em dia;${indicadores.treinamentos.porcentagem}`);
    linhas.push(`Entregas de EPI;Últimos 30 dias;${indicadores.epis.entreguesUltimos30Dias}`);
  } else if (nome === 'colaboradores') {
    linhas.push('Matrícula;Nome;CPF;E-mail;Cargo;Setor;Situação');
    for (const colaborador of estado.colaboradores) {
      linhas.push(
        [
          colaborador.matricula,
          colaborador.nome,
          colaborador.cpf,
          colaborador.email,
          colaborador.cargo,
          colaborador.setor,
          colaborador.status,
        ].join(';'),
      );
    }
  } else if (nome === 'epis') {
    linhas.push('Descrição;CA;Inclusão;Validade;Quantidade');
    for (const epi of estado.epis) {
      linhas.push([epi.descricao, epi.ca, epi.inclusao, epi.validade, epi.quantidade].join(';'));
    }
  } else if (nome === 'entregas-epis') {
    linhas.push('Data;Colaborador;Matrícula;EPI;CA;Quantidade;Assinatura');
    for (const entrega of estado.entregasEpis.map((item) => serializarEntrega(estado, item))) {
      linhas.push(
        [
          entrega.dataEntrega,
          entrega.colaborador,
          entrega.matricula,
          entrega.epi,
          entrega.ca,
          entrega.quantidade,
          entrega.assinatura || 'Sem assinatura',
        ].join(';'),
      );
    }
  } else if (nome === 'certificacoes') {
    linhas.push('Colaborador;Treinamento;Instituição;Carga horária;Emissão;Validade;Situação');
    for (const certificacao of estado.certificacoes.map((item) =>
      serializarCertificacao(estado, item),
    )) {
      linhas.push(
        [
          certificacao.colaborador,
          certificacao.treinamento,
          certificacao.instituicao,
          certificacao.cargaHoraria,
          certificacao.emitidaEm,
          certificacao.validade,
          certificacao.status,
        ].join(';'),
      );
    }
  } else if (nome === 'matriz-treinamentos') {
    linhas.push('Colaborador;Cargo;Treinamento;Conclusão;Validade;Situação');
    for (const vinculo of estado.vinculos.map((item) => serializarVinculo(estado, item))) {
      const hoje = hojeIso();
      const situacao = !vinculo.validade
        ? 'Pendente'
        : vinculo.validade < hoje
          ? 'Vencido'
          : 'Em dia';
      linhas.push(
        [
          vinculo.colaborador,
          vinculo.cargo,
          vinculo.treinamento,
          vinculo.dataConclusao ?? '-',
          vinculo.validade ?? '-',
          situacao,
        ].join(';'),
      );
    }
  } else {
    return null;
  }

  return `\ufeff${linhas.join('\r\n')}\r\n`;
}
