import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Erro devolvido pela API, com a mesma precedência de mensagens do web
/// (`detalhes` antes de `mensagem`).
class ApiException implements Exception {
  final String mensagem;
  ApiException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Cliente HTTP único do app: injeta o Bearer token, monta a URL base e
/// traduz as respostas de erro da API para [ApiException].
class ApiClient {
  ApiClient({required this.token, http.Client? cliente})
      : _cliente = cliente ?? http.Client();

  /// Devolve o token da sessão atual (ou `null` quando não há sessão).
  final String? Function() token;
  final http.Client _cliente;

  Map<String, String> get _cabecalhos {
    final t = token();
    return {
      'Content-Type': 'application/json',
      if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
    };
  }

  Uri _uri(String caminho, [Map<String, String>? query]) {
    final base = Uri.parse('${ApiConfig.baseUrl}$caminho');
    if (query == null || query.isEmpty) return base;
    return base.replace(queryParameters: {...base.queryParameters, ...query});
  }

  Future<dynamic> get(String caminho, {Map<String, String>? query}) async {
    final resposta = await _cliente
        .get(_uri(caminho, query), headers: _cabecalhos)
        .timeout(ApiConfig.timeout);
    return _decodificar(resposta);
  }

  Future<dynamic> post(String caminho, [Object? corpo]) async {
    final resposta = await _cliente
        .post(_uri(caminho), headers: _cabecalhos, body: jsonEncode(corpo ?? {}))
        .timeout(ApiConfig.timeout);
    return _decodificar(resposta);
  }

  Future<dynamic> put(String caminho, [Object? corpo]) async {
    final resposta = await _cliente
        .put(_uri(caminho), headers: _cabecalhos, body: jsonEncode(corpo ?? {}))
        .timeout(ApiConfig.timeout);
    return _decodificar(resposta);
  }

  Future<void> delete(String caminho) async {
    final resposta = await _cliente
        .delete(_uri(caminho), headers: _cabecalhos)
        .timeout(ApiConfig.timeout);
    _decodificar(resposta);
  }

  dynamic _decodificar(http.Response resposta) {
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      if (resposta.bodyBytes.isEmpty) return null;
      final texto = utf8.decode(resposta.bodyBytes);
      if (texto.trim().isEmpty) return null;
      return jsonDecode(texto);
    }

    if (resposta.statusCode == 401) {
      throw ApiException('Sessão expirada. Entre novamente.');
    }

    throw ApiException(_mensagemDeErro(resposta));
  }

  String _mensagemDeErro(http.Response resposta) {
    try {
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (corpo is Map<String, dynamic>) {
        final detalhes = corpo['detalhes'];
        if (detalhes is List && detalhes.isNotEmpty) {
          return detalhes.join(' ');
        }
        final mensagem = corpo['mensagem'];
        if (mensagem is String && mensagem.isNotEmpty) return mensagem;
      }
    } catch (_) {
      // Corpo não-JSON: cai na mensagem genérica abaixo.
    }

    return 'Não foi possível concluir a operação (${resposta.statusCode}).';
  }
}
