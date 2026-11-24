/// Porta de `src/app/models/treinamento-avancado.model.ts`.
class VinculoTreinamento {
  final int id;
  final int colaboradorId;
  final int treinamentoId;
  final String colaborador;
  final String cargo;
  final String treinamento;
  final String? dataConclusao;
  final String status;
  final String? validade;

  VinculoTreinamento({
    required this.id,
    required this.colaboradorId,
    required this.treinamentoId,
    required this.colaborador,
    required this.cargo,
    required this.treinamento,
    required this.dataConclusao,
    required this.status,
    required this.validade,
  });

  factory VinculoTreinamento.fromJson(Map<String, dynamic> j) => VinculoTreinamento(
        id: (j['id'] ?? 0) as int,
        colaboradorId: (j['colaboradorId'] ?? 0) as int,
        treinamentoId: (j['treinamentoId'] ?? 0) as int,
        colaborador: (j['colaborador'] ?? '') as String,
        cargo: (j['cargo'] ?? '') as String,
        treinamento: (j['treinamento'] ?? '') as String,
        dataConclusao: j['dataConclusao'] as String?,
        status: (j['status'] ?? '') as String,
        validade: j['validade'] as String?,
      );
}

class Certificacao {
  final int id;
  final int colaboradorId;
  final String colaborador;
  final String cargo;
  final int treinamentoId;
  final String treinamento;
  final String instituicao;
  final String cargaHoraria;
  final String emitidaEm;
  final String validade;
  final String status;

  Certificacao({
    required this.id,
    required this.colaboradorId,
    required this.colaborador,
    required this.cargo,
    required this.treinamentoId,
    required this.treinamento,
    required this.instituicao,
    required this.cargaHoraria,
    required this.emitidaEm,
    required this.validade,
    required this.status,
  });

  factory Certificacao.fromJson(Map<String, dynamic> j) => Certificacao(
        id: (j['id'] ?? 0) as int,
        colaboradorId: (j['colaboradorId'] ?? 0) as int,
        colaborador: (j['colaborador'] ?? '') as String,
        cargo: (j['cargo'] ?? '') as String,
        treinamentoId: (j['treinamentoId'] ?? 0) as int,
        treinamento: (j['treinamento'] ?? '') as String,
        instituicao: (j['instituicao'] ?? '') as String,
        cargaHoraria: (j['cargaHoraria'] ?? '') as String,
        emitidaEm: (j['emitidaEm'] ?? '') as String,
        validade: (j['validade'] ?? '') as String,
        status: (j['status'] ?? '') as String,
      );
}

class CargoTreinamentoItem {
  final int treinamentoId;
  final String treinamento;
  final String? nr;
  final bool obrigatorio;

  CargoTreinamentoItem({
    required this.treinamentoId,
    required this.treinamento,
    required this.nr,
    required this.obrigatorio,
  });

  factory CargoTreinamentoItem.fromJson(Map<String, dynamic> j) => CargoTreinamentoItem(
        treinamentoId: (j['treinamentoId'] ?? 0) as int,
        treinamento: (j['treinamento'] ?? '') as String,
        nr: j['nr'] as String?,
        obrigatorio: (j['obrigatorio'] ?? false) as bool,
      );
}

class LntCargo {
  final int id;
  final String cargo;
  final String setor;
  final String status;
  final List<CargoTreinamentoItem> treinamentos;

  LntCargo({
    required this.id,
    required this.cargo,
    required this.setor,
    required this.status,
    required this.treinamentos,
  });

  factory LntCargo.fromJson(Map<String, dynamic> j) => LntCargo(
        id: (j['id'] ?? 0) as int,
        cargo: (j['cargo'] ?? '') as String,
        setor: (j['setor'] ?? '') as String,
        status: (j['status'] ?? '') as String,
        treinamentos: ((j['treinamentos'] as List?) ?? [])
            .map((t) => CargoTreinamentoItem.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  List<String> get obrigatorios => treinamentos
      .where((t) => t.obrigatorio)
      .map((t) => t.treinamento)
      .toList();
}

class LntColaborador {
  final int colaboradorId;
  final String colaborador;
  final String cargo;
  final String setor;
  final List<String> treinamentosPendentes;
  final String status;

  LntColaborador({
    required this.colaboradorId,
    required this.colaborador,
    required this.cargo,
    required this.setor,
    required this.treinamentosPendentes,
    required this.status,
  });

  factory LntColaborador.fromJson(Map<String, dynamic> j) => LntColaborador(
        colaboradorId: (j['colaboradorId'] ?? 0) as int,
        colaborador: (j['colaborador'] ?? '') as String,
        cargo: (j['cargo'] ?? '') as String,
        setor: (j['setor'] ?? '') as String,
        treinamentosPendentes: ((j['treinamentosPendentes'] as List?) ?? [])
            .map((t) => t.toString())
            .toList(),
        status: (j['status'] ?? '') as String,
      );
}

class Reciclagem {
  final int colaboradorId;
  final String colaborador;
  final String cargo;
  final int treinamentoId;
  final String treinamento;
  final String prazoMaximo;
  final int diasRestantes;
  final String status;

  Reciclagem({
    required this.colaboradorId,
    required this.colaborador,
    required this.cargo,
    required this.treinamentoId,
    required this.treinamento,
    required this.prazoMaximo,
    required this.diasRestantes,
    required this.status,
  });

  factory Reciclagem.fromJson(Map<String, dynamic> j) => Reciclagem(
        colaboradorId: (j['colaboradorId'] ?? 0) as int,
        colaborador: (j['colaborador'] ?? '') as String,
        cargo: (j['cargo'] ?? '') as String,
        treinamentoId: (j['treinamentoId'] ?? 0) as int,
        treinamento: (j['treinamento'] ?? '') as String,
        prazoMaximo: (j['prazoMaximo'] ?? '') as String,
        diasRestantes: (j['diasRestantes'] ?? 0) as int,
        status: (j['status'] ?? '') as String,
      );
}

class TurmaReciclagem {
  final int id;
  final int treinamentoId;
  final String treinamento;
  final String instrutor;
  final String dataAgendada;
  final int vagas;
  final String status;

  TurmaReciclagem({
    required this.id,
    required this.treinamentoId,
    required this.treinamento,
    required this.instrutor,
    required this.dataAgendada,
    required this.vagas,
    required this.status,
  });

  factory TurmaReciclagem.fromJson(Map<String, dynamic> j) => TurmaReciclagem(
        id: (j['id'] ?? 0) as int,
        treinamentoId: (j['treinamentoId'] ?? 0) as int,
        treinamento: (j['treinamento'] ?? '') as String,
        instrutor: (j['instrutor'] ?? '') as String,
        dataAgendada: (j['dataAgendada'] ?? '') as String,
        vagas: (j['vagas'] ?? 0) as int,
        status: (j['status'] ?? '') as String,
      );
}
