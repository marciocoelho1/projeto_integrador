/// Porta de `src/app/service/chamado.service.ts`.
class Chamado {
  final int id;
  final String tipo;
  final String descricao;
  final int? usuarioId;
  final String solicitante;
  final String status;
  final String abertoEm;
  final String? concluidoEm;

  Chamado({
    required this.id,
    required this.tipo,
    required this.descricao,
    required this.usuarioId,
    required this.solicitante,
    required this.status,
    required this.abertoEm,
    required this.concluidoEm,
  });

  factory Chamado.fromJson(Map<String, dynamic> j) => Chamado(
        id: (j['id'] ?? 0) as int,
        tipo: (j['tipo'] ?? '') as String,
        descricao: (j['descricao'] ?? '') as String,
        usuarioId: j['usuarioId'] as int?,
        solicitante: (j['solicitante'] ?? '') as String,
        status: (j['status'] ?? '') as String,
        abertoEm: (j['abertoEm'] ?? '') as String,
        concluidoEm: j['concluidoEm'] as String?,
      );
}
