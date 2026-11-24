/// Porta de `src/app/service/configuracoes-globais.service.ts` e
/// `src/app/service/audit.service.ts`.
class RegraAlerta {
  final String codigo;
  final String nomeRegra;
  final String descricaoRegra;
  final bool ativa;

  RegraAlerta({
    required this.codigo,
    required this.nomeRegra,
    required this.descricaoRegra,
    required this.ativa,
  });

  factory RegraAlerta.fromJson(Map<String, dynamic> j) => RegraAlerta(
        codigo: (j['codigo'] ?? '') as String,
        nomeRegra: (j['nomeRegra'] ?? '') as String,
        descricaoRegra: (j['descricaoRegra'] ?? '') as String,
        ativa: (j['ativa'] ?? false) as bool,
      );

  RegraAlerta copiarCom({bool? ativa}) => RegraAlerta(
        codigo: codigo,
        nomeRegra: nomeRegra,
        descricaoRegra: descricaoRegra,
        ativa: ativa ?? this.ativa,
      );
}

class ParametroSistema {
  final String chave;
  final String valor;
  final String descricao;

  ParametroSistema({required this.chave, required this.valor, required this.descricao});

  factory ParametroSistema.fromJson(Map<String, dynamic> j) => ParametroSistema(
        chave: (j['chave'] ?? '') as String,
        valor: (j['valor'] ?? '') as String,
        descricao: (j['descricao'] ?? '') as String,
      );

  ParametroSistema copiarCom({String? valor}) => ParametroSistema(
        chave: chave,
        valor: valor ?? this.valor,
        descricao: descricao,
      );
}

class LogAuditoria {
  final int id;
  final String dataHora;
  final String usuario;
  final String modulo;
  final String acao;
  final String descricao;

  LogAuditoria({
    required this.id,
    required this.dataHora,
    required this.usuario,
    required this.modulo,
    required this.acao,
    required this.descricao,
  });

  factory LogAuditoria.fromJson(Map<String, dynamic> j) => LogAuditoria(
        id: (j['id'] ?? 0) as int,
        dataHora: (j['dataHora'] ?? '') as String,
        usuario: (j['usuario'] ?? 'Sistema') as String,
        modulo: (j['modulo'] ?? '') as String,
        acao: (j['acao'] ?? '') as String,
        descricao: (j['descricao'] ?? '') as String,
      );
}
