import '../models/chamado.dart';
import 'auth_service.dart';

/// Porta de `src/app/service/chamado.service.ts`.
class ChamadoService {
  ChamadoService(this._auth);

  final AuthService _auth;
  static const _url = '/chamados';

  Future<List<Chamado>> listar({String? status, bool meus = false}) async {
    final json = await _auth.api.get(_url, query: {
      if (status != null && status.isNotEmpty) 'status': status,
      if (meus) 'meus': 'true',
    }) as List;
    return json.map((e) => Chamado.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Chamado> criar({required String tipo, required String descricao}) async {
    final json = await _auth.api.post(_url, {'tipo': tipo, 'descricao': descricao})
        as Map<String, dynamic>;
    return Chamado.fromJson(json);
  }

  Future<Chamado> atualizarStatus({
    required int id,
    required String tipo,
    required String descricao,
    required String status,
  }) async {
    final json = await _auth.api
        .put('$_url/$id', {'tipo': tipo, 'descricao': descricao, 'status': status})
        as Map<String, dynamic>;
    return Chamado.fromJson(json);
  }

  Future<void> excluir(int id) => _auth.api.delete('$_url/$id');
}
