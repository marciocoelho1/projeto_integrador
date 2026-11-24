/// Porta de `src/app/models/colaborador.model.ts`.
class Colaborador {
  final int id;
  final String matricula;
  final String nome;
  final String cpf;
  final String email;
  final String cargo;
  final String setor;
  final String status;

  Colaborador({
    required this.id,
    required this.matricula,
    required this.nome,
    required this.cpf,
    required this.email,
    required this.cargo,
    required this.setor,
    required this.status,
  });

  factory Colaborador.fromJson(Map<String, dynamic> j) => Colaborador(
        id: j['id'] as int,
        matricula: (j['matricula'] ?? '') as String,
        nome: (j['nome'] ?? '') as String,
        cpf: (j['cpf'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        cargo: (j['cargo'] ?? '') as String,
        setor: (j['setor'] ?? '') as String,
        status: (j['status'] ?? '') as String,
      );

  Colaborador copiarCom({
    String? matricula,
    String? nome,
    String? cpf,
    String? email,
    String? cargo,
    String? setor,
    String? status,
  }) =>
      Colaborador(
        id: id,
        matricula: matricula ?? this.matricula,
        nome: nome ?? this.nome,
        cpf: cpf ?? this.cpf,
        email: email ?? this.email,
        cargo: cargo ?? this.cargo,
        setor: setor ?? this.setor,
        status: status ?? this.status,
      );

  Map<String, dynamic> paraRequisicao() => {
        'matricula': matricula.trim(),
        'nome': nome.trim(),
        'cpf': cpf.trim(),
        'email': email.trim(),
        'cargo': cargo.trim(),
        'setor': setor.trim(),
        'status': status,
      };
}
