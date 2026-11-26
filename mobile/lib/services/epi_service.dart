import '../models/epi.dart';
import 'auth_service.dart';

/// Porta de `src/app/service/epis.service.ts` (estoque + entregas).
class EpiService {
  EpiService(this._auth);

  final AuthService _auth;
  static const _url = '/epis';
  static const _urlEntregas = '/entregas-epis';

  /* ------- Estoque / cadastro ------- */

  Future<List<Epi>> obterEpis() async {
    final json = await _auth.api.get(_url) as List;
    return json.map((e) => Epi.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Epi> obterEpiPorId(int id) async {
    final json = await _auth.api.get('$_url/$id') as Map<String, dynamic>;
    return Epi.fromJson(json);
  }

  Future<Epi> cadastrarEpi(Map<String, dynamic> dados) async {
    final json = await _auth.api.post(_url, dados) as Map<String, dynamic>;
    return Epi.fromJson(json);
  }

  Future<Epi> atualizarEpi(int id, Map<String, dynamic> dados) async {
    final json = await _auth.api.put('$_url/$id', dados) as Map<String, dynamic>;
    return Epi.fromJson(json);
  }

  Future<void> excluirEpi(int id) => _auth.api.delete('$_url/$id');

  /* ------- Entregas ------- */

  /// Com [colaboradorId] devolve só as entregas daquele colaborador.
  Future<List<EntregaEpi>> obterEntregas({int? colaboradorId}) async {
    final json = await _auth.api.get(
      _urlEntregas,
      query: colaboradorId == null ? null : {'colaboradorId': '$colaboradorId'},
    ) as List;
    return json.map((e) => EntregaEpi.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EntregaEpi> registrarEntrega(Map<String, dynamic> dados) async {
    final json = await _auth.api.post(_urlEntregas, dados) as Map<String, dynamic>;
    return EntregaEpi.fromJson(json);
  }

  Future<void> excluirEntrega(int id) => _auth.api.delete('$_urlEntregas/$id');
}
