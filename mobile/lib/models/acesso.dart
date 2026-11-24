/// Porta de `src/app/service/acesso.service.ts`.
class UsuarioApi {
  final int id;
  final String nomeCompleto;
  final String login;
  final String email;
  final String cpf;
  final int grupoId;
  final String grupo;
  final String status;
  final List<String> modulos;

  UsuarioApi({
    required this.id,
    required this.nomeCompleto,
    required this.login,
    required this.email,
    required this.cpf,
    required this.grupoId,
    required this.grupo,
    required this.status,
    required this.modulos,
  });

  factory UsuarioApi.fromJson(Map<String, dynamic> j) => UsuarioApi(
        id: (j['id'] ?? 0) as int,
        nomeCompleto: (j['nomeCompleto'] ?? '') as String,
        login: (j['login'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        cpf: (j['cpf'] ?? '') as String,
        grupoId: (j['grupoId'] ?? 0) as int,
        grupo: (j['grupo'] ?? '') as String,
        status: (j['status'] ?? '') as String,
        modulos: ((j['modulos'] as List?) ?? []).map((m) => m.toString()).toList(),
      );
}

class GrupoApi {
  final int id;
  final String nomenclatura;
  final String finalidade;
  final List<String> modulos;

  GrupoApi({
    required this.id,
    required this.nomenclatura,
    required this.finalidade,
    required this.modulos,
  });

  factory GrupoApi.fromJson(Map<String, dynamic> j) => GrupoApi(
        id: (j['id'] ?? 0) as int,
        nomenclatura: (j['nomenclatura'] ?? '') as String,
        finalidade: (j['finalidade'] ?? '') as String,
        modulos: ((j['modulos'] as List?) ?? []).map((m) => m.toString()).toList(),
      );
}

class ModuloApi {
  final String chave;
  final String titulo;
  final String detalhe;

  ModuloApi({required this.chave, required this.titulo, required this.detalhe});

  factory ModuloApi.fromJson(Map<String, dynamic> j) => ModuloApi(
        chave: (j['chave'] ?? '') as String,
        titulo: (j['titulo'] ?? '') as String,
        detalhe: (j['detalhe'] ?? '') as String,
      );
}
