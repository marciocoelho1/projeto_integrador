import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

/// Porta de `src/app/service/relatorio.service.ts`: baixa os relatórios CSV que o
/// servidor monta a partir do banco.
///
/// O arquivo vem de `GET /api/relatorios/{nome}.csv`, e não do que a tela já
/// carregou — por isso o CSV sai completo mesmo com a lista filtrada na tela.
class RelatorioService {
  final AuthService _auth;
  RelatorioService(this._auth);

  /// Relatórios oferecidos pelo backend, na mesma ordem do web.
  static const relatorios = <String>[
    'dashboard',
    'matriz-treinamentos',
    'colaboradores',
    'epis',
    'certificacoes',
    'entregas-epis',
  ];

  /// Conteúdo do CSV. O BOM que o backend envia é preservado para o Excel em
  /// português abrir os acentos corretamente.
  Future<String> baixar(String relatorio) async {
    final resposta = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/relatorios/$relatorio.csv'),
          headers: _auth.cabecalhoAuth,
        )
        .timeout(ApiConfig.timeout);

    if (resposta.statusCode == 401) {
      throw AuthException('Sessão expirada. Entre novamente.');
    }
    if (resposta.statusCode != 200) {
      throw Exception('Falha ao gerar o relatório (${resposta.statusCode}).');
    }

    return utf8.decode(resposta.bodyBytes);
  }
}