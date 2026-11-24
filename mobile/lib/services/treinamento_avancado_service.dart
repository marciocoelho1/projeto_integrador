import '../models/treinamento_avancado.dart';
import 'auth_service.dart';

/// Porta de `src/app/service/treinamento-avancado.service.ts`: matriz LNT,
/// vínculos, certificações, turmas e reciclagens.
class TreinamentoAvancadoService {
  TreinamentoAvancadoService(this._auth);

  final AuthService _auth;

  Map<String, String>? _filtro(String chave, int? valor) =>
      valor == null ? null : {chave: '$valor'};

  /* ------- Vínculos ------- */

  Future<List<VinculoTreinamento>> listarVinculos({int? colaboradorId}) async {
    final json = await _auth.api.get('/vinculos', query: _filtro('colaboradorId', colaboradorId)) as List;
    return json.map((e) => VinculoTreinamento.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<VinculoTreinamento> criarVinculo(Map<String, dynamic> dados) async {
    final json = await _auth.api.post('/vinculos', dados) as Map<String, dynamic>;
    return VinculoTreinamento.fromJson(json);
  }

  Future<VinculoTreinamento> atualizarVinculo(int id, Map<String, dynamic> dados) async {
    final json = await _auth.api.put('/vinculos/$id', dados) as Map<String, dynamic>;
    return VinculoTreinamento.fromJson(json);
  }

  Future<void> excluirVinculo(int id) => _auth.api.delete('/vinculos/$id');

  /* ------- Certificações ------- */

  Future<List<Certificacao>> listarCertificacoes({int? colaboradorId}) async {
    final json = await _auth.api.get('/certificacoes', query: _filtro('colaboradorId', colaboradorId)) as List;
    return json.map((e) => Certificacao.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Certificacao> criarCertificacao(Map<String, dynamic> dados) async {
    final json = await _auth.api.post('/certificacoes', dados) as Map<String, dynamic>;
    return Certificacao.fromJson(json);
  }

  Future<Certificacao> atualizarCertificacao(int id, Map<String, dynamic> dados) async {
    final json = await _auth.api.put('/certificacoes/$id', dados) as Map<String, dynamic>;
    return Certificacao.fromJson(json);
  }

  Future<void> excluirCertificacao(int id) => _auth.api.delete('/certificacoes/$id');

  /* ------- LNT / Cargos ------- */

  Future<List<LntCargo>> listarLnt() async {
    final json = await _auth.api.get('/lnt') as List;
    return json.map((e) => LntCargo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<LntColaborador>> listarLntColaboradores() async {
    final json = await _auth.api.get('/lnt/colaboradores') as List;
    return json.map((e) => LntColaborador.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// PUT /api/cargos/{id}/treinamentos — substitui a matriz LNT do cargo.
  Future<void> atualizarMatrizCargo(int cargoId, List<CargoTreinamentoItem> treinamentos) async {
    await _auth.api.put('/cargos/$cargoId/treinamentos', {
      'treinamentos': treinamentos
          .map((t) => {'treinamentoId': t.treinamentoId, 'obrigatorio': t.obrigatorio})
          .toList(),
    });
  }

  /* ------- Reciclagens ------- */

  Future<List<TurmaReciclagem>> listarTurmasReciclagem({int? treinamentoId}) async {
    final json = await _auth.api.get(
      '/turmas-reciclagem',
      query: _filtro('treinamentoId', treinamentoId),
    ) as List;
    return json.map((e) => TurmaReciclagem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TurmaReciclagem> criarTurmaReciclagem(Map<String, dynamic> dados) async {
    final json = await _auth.api.post('/turmas-reciclagem', dados) as Map<String, dynamic>;
    return TurmaReciclagem.fromJson(json);
  }

  Future<TurmaReciclagem> atualizarTurmaReciclagem(int id, Map<String, dynamic> dados) async {
    final json = await _auth.api.put('/turmas-reciclagem/$id', dados) as Map<String, dynamic>;
    return TurmaReciclagem.fromJson(json);
  }

  Future<void> excluirTurmaReciclagem(int id) => _auth.api.delete('/turmas-reciclagem/$id');

  /// Reciclagens derivadas da validade dos vínculos (GET /api/reciclagens).
  Future<List<Reciclagem>> listarReciclagens() async {
    final json = await _auth.api.get('/reciclagens') as List;
    return json.map((e) => Reciclagem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
