import 'package:flutter/foundation.dart';

/// Endereço da API do SGSST em cada ambiente.
class ApiConfig {
  // Permite trocar sem editar código:
  // flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080/api
  static const String _urlDefinida = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_urlDefinida.isNotEmpty) return _urlDefinida;

    // No emulador Android, "localhost" é o próprio emulador;
    // 10.0.2.2 é a máquina que roda a API.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api';
    }

    return 'http://localhost:8080/api';
  }

  /// Em produção (Render):
  /// flutter build apk --dart-define=API_BASE_URL=https://sgsst-api-r3iv.onrender.com/api
  static const Duration timeout = Duration(seconds: 15);
}