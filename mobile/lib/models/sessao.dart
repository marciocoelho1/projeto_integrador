/// Usuário autenticado, como o backend devolve em /api/auth/login.
class Sessao {
  final String token;
  final DateTime expiraEm;
  final int id;
  final String login;
  final String nomeCompleto;
  final String grupo;
  final List<String> modulos;

  Sessao({
    required this.token,
    required this.expiraEm,
    required this.id,
    required this.login,
    required this.nomeCompleto,
    required this.grupo,
    required this.modulos,
  });

  bool get expirada => DateTime.now().isAfter(expiraEm);

  factory Sessao.fromJson(Map<String, dynamic> json) {
    final usuario = json['usuario'] as Map<String, dynamic>;

    return Sessao(
      token: json['token'] as String,
      expiraEm: DateTime.parse(json['expiraEm'] as String).toLocal(),
      id: usuario['id'] as int,
      login: usuario['login'] as String,
      nomeCompleto: usuario['nomeCompleto'] as String,
      grupo: (usuario['grupo'] ?? '') as String,
      modulos: ((usuario['modulos'] as List?) ?? [])
          .map((m) => m.toString())
          .toList(),
    );
  }
}