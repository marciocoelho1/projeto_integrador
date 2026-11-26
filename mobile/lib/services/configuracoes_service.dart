import '../models/configuracao.dart';
import 'auth_service.dart';

/// Porta de `src/app/service/configuracoes-globais.service.ts`.
class ConfiguracoesService {
  ConfiguracoesService(this._auth);

  final AuthService _auth;
  static const _regras = '/regras-alerta';
  static const _parametros = '/parametros';

  Future<List<RegraAlerta>> listarRegras() async {
    final json = await _auth.api.get(_regras) as List;
    return json.map((e) => RegraAlerta.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ParametroSistema>> listarParametros() async {
    final json = await _auth.api.get(_parametros) as List;
    return json.map((e) => ParametroSistema.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// PUT /api/regras-alerta/{codigo}: liga ou desliga a regra.
  Future<RegraAlerta> definirAtiva(String codigo, bool ativa) async {
    final json = await _auth.api.put('$_regras/$codigo', {'ativa': ativa}) as Map<String, dynamic>;
    return RegraAlerta.fromJson(json);
  }

  /// PUT /api/parametros/{chave}: grava o novo valor do parâmetro.
  Future<ParametroSistema> salvarValor(String chave, String valor) async {
    final json = await _auth.api.put('$_parametros/$chave', {'valor': valor})
        as Map<String, dynamic>;
    return ParametroSistema.fromJson(json);
  }
}
