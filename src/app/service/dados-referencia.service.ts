import { Injectable, signal } from '@angular/core';

export type ChaveModulo =
  | 'sgst_dashboard'
  | 'sgst_colaboradores'
  | 'sgst_epis'
  | 'sgst_treinamentos'
  | 'sgst_relatorios'
  | 'sgst_config';

export interface GrupoAcesso {
  id: string;
  nomenclatura: string;
  finalidade: string;
  modulosLiberados: ChaveModulo[];
}

@Injectable({
  providedIn: 'root',
})
export class DadosReferenciaService {
  readonly cargosCadastrados: string[] = [
    'Açougueiro',
    'Açougueira',
    'Operador de Caixa',
    'Operadora de Caixa',
    'Repositor',
    'Repositora',
    'Padeiro / Confeiteiro',
    'Padeiro',
    'Operador de Empilhadeira',
    'Fiscal de Prevenção de Perdas',
    'Auxiliar de Limpeza',
  ];

  readonly setoresCadastrados: string[] = [
    'Açougue',
    'Frente de Loja',
    'Mercearia',
    'Padaria',
    'Estoque',
    'Estoque / Logística',
    'Higienização',
  ];

  readonly gruposAcesso = signal<GrupoAcesso[]>([
    {
      id: 'admin_tst',
      nomenclatura: 'Administrador TST',
      finalidade: 'Acesso irrestrito para Técnicos e Engenheiros de Segurança.',
      modulosLiberados: [
        'sgst_dashboard',
        'sgst_colaboradores',
        'sgst_epis',
        'sgst_treinamentos',
        'sgst_relatorios',
        'sgst_config',
      ],
    },
    {
      id: 'colaborador',
      nomenclatura: 'Colaborador',
      finalidade: 'Foco exclusivo na entrega e estoque de equipamentos.',
      modulosLiberados: ['sgst_dashboard', 'sgst_epis', 'sgst_relatorios'],
    },
  ]);
}
