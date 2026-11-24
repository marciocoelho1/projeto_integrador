/// Porta de `src/app/models/treinamento.model.ts`.
class Treinamento {
  final int id;
  final String codigo;
  final String nome;
  final String classificacao;
  final String? nr;
  final String cargaHoraria;
  final int? validadeMeses;
  final String status;

  Treinamento({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.classificacao,
    required this.nr,
    required this.cargaHoraria,
    required this.validadeMeses,
    required this.status,
  });

  factory Treinamento.fromJson(Map<String, dynamic> j) => Treinamento(
        id: (j['id'] ?? 0) as int,
        codigo: (j['codigo'] ?? '') as String,
        nome: (j['nome'] ?? '') as String,
        classificacao: (j['classificacao'] ?? '') as String,
        nr: j['nr'] as String?,
        cargaHoraria: (j['cargaHoraria'] ?? '') as String,
        validadeMeses: j['validadeMeses'] as int?,
        status: (j['status'] ?? 'Ativo') as String,
      );
}
