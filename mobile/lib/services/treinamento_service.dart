import '../models/treinamento.dart';
import 'auth_service.dart';

/// Porta de `src/app/service/treinamento.service.ts`.
class TreinamentoService {
  TreinamentoService(this._auth);

  final AuthService _auth;
  static const _url = '/treinamentos';

  Future<List<Treinamento>> listar() async {
    final json = await _auth.api.get(_url) as List;
    return json.map((e) => Treinamento.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Treinamento> buscarPorId(int id) async {
    final json = await _auth.api.get('$_url/$id') as Map<String, dynamic>;
    return Treinamento.fromJson(json);
  }

  Future<Treinamento> criar(Map<String, dynamic> dados) async {
    final json = await _auth.api.post(_url, dados) as Map<String, dynamic>;
    return Treinamento.fromJson(json);
  }

  Future<Treinamento> atualizar(int id, Map<String, dynamic> dados) async {
    final json = await _auth.api.put('$_url/$id', dados) as Map<String, dynamic>;
    return Treinamento.fromJson(json);
  }

  Future<void> excluir(int id) => _auth.api.delete('$_url/$id');
}
