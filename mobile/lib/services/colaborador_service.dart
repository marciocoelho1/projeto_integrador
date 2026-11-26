import '../models/colaborador.dart';
import 'auth_service.dart';

/// Porta de `src/app/service/colaborador.service.ts`.
class ColaboradorService {
  ColaboradorService(this._auth);

  final AuthService _auth;
  static const _url = '/colaboradores';

  Future<List<Colaborador>> listar() async {
    final json = await _auth.api.get(_url) as List;
    return json.map((e) => Colaborador.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Colaborador> buscarPorId(int id) async {
    final json = await _auth.api.get('$_url/$id') as Map<String, dynamic>;
    return Colaborador.fromJson(json);
  }

  Future<Colaborador> criar(Map<String, dynamic> dados) async {
    final json = await _auth.api.post(_url, dados) as Map<String, dynamic>;
    return Colaborador.fromJson(json);
  }

  Future<Colaborador> atualizar(int id, Map<String, dynamic> dados) async {
    final json = await _auth.api.put('$_url/$id', dados) as Map<String, dynamic>;
    return Colaborador.fromJson(json);
  }

  Future<void> excluir(int id) => _auth.api.delete('$_url/$id');
}
