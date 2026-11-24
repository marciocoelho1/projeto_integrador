/// Porta de `src/app/service/importacao.service.ts`.
enum TipoImportacao { colaborador, treinamento, epi }

extension TipoImportacaoRotulo on TipoImportacao {
  String get rotulo => switch (this) {
        TipoImportacao.colaborador => 'Colaboradores',
        TipoImportacao.treinamento => 'Treinamentos',
        TipoImportacao.epi => 'EPIs',
      };

  String get recurso => switch (this) {
        TipoImportacao.colaborador => 'colaboradores',
        TipoImportacao.treinamento => 'treinamentos',
        TipoImportacao.epi => 'epis',
      };

  String get arquivoModelo => 'template_$recurso.csv';
}

class ImportacaoErro {
  final int linha;
  final String mensagem;

  ImportacaoErro({required this.linha, required this.mensagem});

  factory ImportacaoErro.fromJson(Map<String, dynamic> j) => ImportacaoErro(
        linha: (j['linha'] ?? 0) as int,
        mensagem: (j['mensagem'] ?? '') as String,
      );
}

class ImportacaoResultado {
  final int total;
  final int importados;
  final int ignorados;
  final List<ImportacaoErro> erros;

  ImportacaoResultado({
    required this.total,
    required this.importados,
    required this.ignorados,
    required this.erros,
  });

  factory ImportacaoResultado.fromJson(Map<String, dynamic> j) => ImportacaoResultado(
        total: (j['total'] ?? 0) as int,
        importados: (j['importados'] ?? 0) as int,
        ignorados: (j['ignorados'] ?? 0) as int,
        erros: ((j['erros'] as List?) ?? [])
            .map((e) => ImportacaoErro.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
