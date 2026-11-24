import '../models/importacao.dart';
import 'auth_service.dart';

/// Porta de `src/app/service/importacao.service.ts`.
class ImportacaoService {
  ImportacaoService(this._auth);

  final AuthService _auth;

  Future<ImportacaoResultado> importar(TipoImportacao tipo, List<Map<String, dynamic>> linhas) async {
    final json = await _auth.api.post('/importacao/${tipo.recurso}', {'linhas': linhas})
        as Map<String, dynamic>;
    return ImportacaoResultado.fromJson(json);
  }
}
