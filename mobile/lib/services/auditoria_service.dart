import '../models/configuracao.dart';
import 'auth_service.dart';

/// Porta de `src/app/service/audit.service.ts`.
class AuditoriaService {
  AuditoriaService(this._auth);

  final AuthService _auth;
  static const _url = '/auditoria';

  Future<List<LogAuditoria>> listar({String? termo, String? inicio, String? fim}) async {
    final json = await _auth.api.get(_url, query: {
      if (termo != null && termo.trim().isNotEmpty) 'termo': termo.trim(),
      if (inicio != null && inicio.isNotEmpty) 'inicio': inicio,
      if (fim != null && fim.isNotEmpty) 'fim': fim,
    }) as List;
    return json.map((e) => LogAuditoria.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/auditoria — eventos manuais (os automáticos são gravados no backend).
  Future<void> registrarAcao({
    required String usuario,
    required String modulo,
    required String acao,
    required String descricao,
  }) async {
    await _auth.api.post(_url, {
      'usuario': usuario,
      'modulo': modulo,
      'acao': acao,
      'descricao': descricao,
    });
  }
}
