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
  ///
  /// Timeout normal das requisições já aquecidas.
  static const Duration timeout = Duration(seconds: 15);

  /// Timeout da *primeira* requisição da sessão.
  ///
  /// O plano gratuito do Render hiberna a instância após alguns minutos sem
  /// tráfego e leva ate ~115 s para acordar. Com o [timeout] padrão o login
  /// desistia antes de a API responder e o usuário via "servidor demorou",
  /// mesmo com tudo funcionando. A primeira chamada usa este prazo maior;
  /// depois dela a API esta acordada e o [timeout] normal passa a valer.
  static const Duration timeoutFrio = Duration(seconds: 120);

  /// Aviso mostrado enquanto a primeira chamada aguarda o servidor acordar.
  static const String mensagemAcordandoServidor =
      'Acordando o servidor… a primeira conexão pode levar ate 2 minutos.';

  // Mensagens de falha de rede. O Render hiberna no plano gratuito e o
  // primeiro acesso pode demorar, entao o aviso explica em vez de exibir a
  // excecao crua do Dart.
  static const String mensagemServidorLento =
      'O servidor demorou para responder. Ele pode estar iniciando — aguarde alguns segundos e tente de novo.';

  static const String mensagemSemConexao =
      'Sem conexao com o servidor. Verifique o Wi-Fi ou os dados moveis e tente novamente.';

  static const String mensagemServidorIndisponivel =
      'O servidor esta indisponivel no momento. Tente novamente em instantes.';
}