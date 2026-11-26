/// Porta dos contratos de `src/app/service/epis.service.ts`.
class Epi {
  final int id;
  final String descricao;
  final int quantidade;
  final String inclusao;
  final String validade;
  final String ca;

  Epi({
    required this.id,
    required this.descricao,
    required this.quantidade,
    required this.inclusao,
    required this.validade,
    required this.ca,
  });

  factory Epi.fromJson(Map<String, dynamic> j) => Epi(
        id: (j['id'] ?? 0) as int,
        descricao: (j['descricao'] ?? '') as String,
        quantidade: (j['quantidade'] ?? 0) as int,
        inclusao: (j['inclusao'] ?? '') as String,
        validade: (j['validade'] ?? '') as String,
        ca: (j['ca'] ?? '') as String,
      );

  bool get estoqueCritico => quantidade < 20;

  Epi copiarCom({
    String? descricao,
    int? quantidade,
    String? inclusao,
    String? validade,
    String? ca,
  }) =>
      Epi(
        id: id,
        descricao: descricao ?? this.descricao,
        quantidade: quantidade ?? this.quantidade,
        inclusao: inclusao ?? this.inclusao,
        validade: validade ?? this.validade,
        ca: ca ?? this.ca,
      );
}

class EntregaEpi {
  final int id;
  final int colaboradorId;
  final String colaborador;
  final String matricula;
  final int epiId;
  final String epi;
  final String ca;
  final int quantidade;
  final String dataEntrega;
  final String assinatura;

  EntregaEpi({
    required this.id,
    required this.colaboradorId,
    required this.colaborador,
    required this.matricula,
    required this.epiId,
    required this.epi,
    required this.ca,
    required this.quantidade,
    required this.dataEntrega,
    required this.assinatura,
  });

  factory EntregaEpi.fromJson(Map<String, dynamic> j) => EntregaEpi(
        id: (j['id'] ?? 0) as int,
        colaboradorId: (j['colaboradorId'] ?? 0) as int,
        colaborador: (j['colaborador'] ?? '') as String,
        matricula: (j['matricula'] ?? '') as String,
        epiId: (j['epiId'] ?? 0) as int,
        epi: (j['epi'] ?? '') as String,
        ca: (j['ca'] ?? '') as String,
        quantidade: (j['quantidade'] ?? 0) as int,
        dataEntrega: (j['dataEntrega'] ?? '') as String,
        assinatura: (j['assinatura'] ?? '') as String,
      );
}
