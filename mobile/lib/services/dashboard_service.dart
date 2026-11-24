import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/indicador.dart';
import 'auth_service.dart';

class DashboardService {
  final AuthService _auth;
  DashboardService(this._auth);

  Future<Indicadores> carregar() async {
    final resposta = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/dashboard/indicadores'),
          headers: _auth.cabecalhoAuth,
        )
        .timeout(ApiConfig.timeout);

    if (resposta.statusCode == 401) {
      throw AuthException('Sessão expirada. Entre novamente.');
    }
    if (resposta.statusCode != 200) {
      throw Exception('Falha ao carregar indicadores (${resposta.statusCode}).');
    }

    final json = jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
    return Indicadores.fromJson(json);
  }
}