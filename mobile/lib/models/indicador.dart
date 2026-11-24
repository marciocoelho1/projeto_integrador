class ResumoColaboradores {
  final int total, ativos, inativos, afastados;
  ResumoColaboradores.fromJson(Map<String, dynamic> j)
      : total = j['total'] as int,
        ativos = j['ativos'] as int,
        inativos = j['inativos'] as int,
        afastados = j['afastados'] as int;
}

class ResumoCertificacoes {
  final int total, ativas, vencidas, vencendoEm30Dias;
  ResumoCertificacoes.fromJson(Map<String, dynamic> j)
      : total = j['total'] as int,
        ativas = j['ativas'] as int,
        vencidas = j['vencidas'] as int,
        vencendoEm30Dias = j['vencendoEm30Dias'] as int;
}

class ResumoEpis {
  final int emEstoque, proximoVencimento, vencidos, entreguesUltimos30Dias, totalTipos;
  ResumoEpis.fromJson(Map<String, dynamic> j)
      : emEstoque = j['emEstoque'] as int,
        proximoVencimento = j['proximoVencimento'] as int,
        vencidos = j['vencidos'] as int,
        entreguesUltimos30Dias = j['entreguesUltimos30Dias'] as int,
        totalTipos = j['totalTipos'] as int;
}

class ResumoTreinamentos {
  final int concluidos, pendentes, vencidos, total, porcentagem;
  ResumoTreinamentos.fromJson(Map<String, dynamic> j)
      : concluidos = j['concluidos'] as int,
        pendentes = j['pendentes'] as int,
        vencidos = j['vencidos'] as int,
        total = j['total'] as int,
        porcentagem = j['porcentagem'] as int;
}

class AlertaIndicador {
  final String tipo, mensagem, criticidade; // alta | media | baixa
  AlertaIndicador.fromJson(Map<String, dynamic> j)
      : tipo = j['tipo'] as String,
        mensagem = j['mensagem'] as String,
        criticidade = j['criticidade'] as String;
}

class Indicadores {
  final ResumoColaboradores colaboradores;
  final ResumoCertificacoes certificacoes;
  final ResumoEpis epis;
  final ResumoTreinamentos treinamentos;
  final List<AlertaIndicador> alertas;
  final DateTime geradoEm;

  Indicadores({
    required this.colaboradores, required this.certificacoes,
    required this.epis, required this.treinamentos,
    required this.alertas, required this.geradoEm,
  });

  factory Indicadores.fromJson(Map<String, dynamic> j) => Indicadores(
        colaboradores: ResumoColaboradores.fromJson(j['colaboradores']),
        certificacoes: ResumoCertificacoes.fromJson(j['certificacoes']),
        epis: ResumoEpis.fromJson(j['epis']),
        treinamentos: ResumoTreinamentos.fromJson(j['treinamentos']),
        alertas: ((j['alertas'] as List?) ?? [])
            .map((a) => AlertaIndicador.fromJson(a as Map<String, dynamic>))
            .toList(),
        geradoEm: DateTime.parse(j['geradoEm'] as String).toLocal(),
      );
}