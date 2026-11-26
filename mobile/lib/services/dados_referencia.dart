/// Porta de `src/app/service/dados-referencia.service.ts`: listas fixas usadas
/// nos formulários de cadastro.
class DadosReferencia {
  static const cargosCadastrados = <String>[
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

  static const setoresCadastrados = <String>[
    'Açougue',
    'Frente de Loja',
    'Mercearia',
    'Padaria',
    'Estoque',
    'Estoque / Logística',
    'Higienização',
  ];
  /// Mesmas NRs do datalist "lista-nr-reciclagem" do web.
  static const nrsReferentes = <String>[
    'NR-06',
    'NR-11',
    'NR-12',
    'NR-17',
    'NR-23',
    'NR-35',
  ];
}
