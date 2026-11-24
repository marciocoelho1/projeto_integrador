import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/sessao.dart';

class AuthException implements Exception {
  final String mensagem;
  AuthException(this.mensagem);
  @override
  String toString() => mensagem;
}

class AuthService {
  static const _chaveToken = 'sgsst.token';
  static const _chaveSessao = 'sgsst.sessao';

  Sessao? _sessao;

  Sessao? get sessao => _sessao;
  String? get token => _sessao?.token;

  /// Recupera a sessão salva ao abrir o app.
  Future<Sessao?> restaurar() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_chaveSessao);
    if (json == null) return null;

    final sessao = Sessao.fromJson(jsonDecode(json) as Map<String, dynamic>);
    if (sessao.expirada) {
      await sair();
      return null;
    }

    _sessao = sessao;
    return sessao;
  }

  Future<Sessao> entrar(String login, String senha) async {
    final resposta = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'login': login.trim(), 'senha': senha}),
        )
        .timeout(ApiConfig.timeout);

    if (resposta.statusCode == 401) {
      throw AuthException('Usuário ou senha inválidos.');
    }
    if (resposta.statusCode != 200) {
      throw AuthException('Não foi possível entrar (${resposta.statusCode}).');
    }

    final json = jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
    final sessao = Sessao.fromJson(json);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveToken, sessao.token);
    await prefs.setString(_chaveSessao, jsonEncode(json));

    _sessao = sessao;
    return sessao;
  }

  Future<void> sair() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveToken);
    await prefs.remove(_chaveSessao);
    _sessao = null;
  }

  /// Cabeçalho padrão para as rotas que exigem Bearer token.
  Map<String, String> get cabecalhoAuth => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_sessao?.token ?? ''}',
      };
}