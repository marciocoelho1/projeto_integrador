import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_sgsst/core/app_theme.dart';
import 'package:app_sgsst/screens/main_screen.dart';
import 'package:app_sgsst/services/auth_service.dart';

/// Cliente HTTP que responde o contrato da API sem rede — assim o teste roda no
/// ambiente do flutter_test (que bloqueia HTTP real).
class _ClienteFalso implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _RequisicaoFalso(method, url);

  @override
  void close({bool force = false}) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RequisicaoFalso implements HttpClientRequest {
  _RequisicaoFalso(this.method, this.uri);

  @override
  final String method;
  @override
  final Uri uri;
  @override
  final HttpHeaders headers = _CabecalhosFalso();
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = true;
  @override
  int contentLength = -1;

  @override
  Future<HttpClientResponse> close() async => _RespostaFalso(_corpo());

  String _corpoEnviado = '';

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    final chunks = await stream.toList();
    _corpoEnviado = utf8.decode(chunks.expand((c) => c).toList(), allowMalformed: true);
  }

  String _corpo() {
    final p = uri.path;
    if (p.endsWith('/auth/login')) {
      final colaborador = _corpoEnviado.contains('colaborador');
      return jsonEncode({
        'token': 'fake',
        'expiraEm': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        'usuario': {
          'id': colaborador ? 2 : 1,
          'login': colaborador ? 'MAT-001' : 'admin',
          'nomeCompleto': colaborador ? 'Maria Souza' : 'Administrador TST',
          'grupo': colaborador ? 'Colaborador' : 'Administrador TST',
          'modulos': ['sgst_dashboard'],
        },
      });
    }
    if (p.contains('/dashboard/indicadores')) {
      return jsonEncode({
        'colaboradores': {'total': 1, 'ativos': 1, 'inativos': 0, 'afastados': 0},
        'certificacoes': {'total': 0, 'ativas': 0, 'vencidas': 0, 'vencendoEm30Dias': 0},
        'epis': {'emEstoque': 5, 'proximoVencimento': 0, 'vencidos': 0, 'entreguesUltimos30Dias': 0, 'totalTipos': 1},
        'treinamentos': {'concluidos': 0, 'pendentes': 0, 'vencidos': 0, 'total': 0, 'porcentagem': 0},
        'alertas': <dynamic>[],
        'geradoEm': DateTime.now().toIso8601String(),
      });
    }
    if (p.contains('/colaboradores')) {
      return jsonEncode([
        {
          'id': 1,
          'matricula': 'MAT-001',
          'nome': 'Maria Souza',
          'cpf': '11122233344',
          'email': 'maria@empresa.com',
          'cargo': 'Repositora',
          'setor': 'Mercearia',
          'status': 'Ativo',
        },
      ]);
    }
    return '[]';
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RespostaFalso implements HttpClientResponse {
  _RespostaFalso(this.corpo);
  final String corpo;
  @override
  int get statusCode => 200;
  @override
  int get contentLength => utf8.encode(corpo).length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  bool get isRedirect => false;
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  String get reasonPhrase => 'OK';
  @override
  bool get persistentConnection => false;
  @override
  final HttpHeaders headers = _CabecalhosFalso();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(Uint8List.fromList(utf8.encode(corpo))).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CabecalhosFalso implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  List<String>? operator [](String name) => null;

  @override
  String? value(String name) => null;

  @override
  void forEach(void Function(String name, List<String> values) action) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('MainScreen monta o menu do perfil admin com todas as telas', (tester) async {
    HttpOverrides.global = _OverridesFalso();
    SharedPreferences.setMockInitialValues({});

    final auth = AuthService();
    await auth.entrar('admin', 'admin123');

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.tema, home: MainScreen(auth: auth)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));

    // Barra inferior com os atalhos do perfil admin.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Colaboradores'), findsWidgets);

    // O menu lateral existe e abre com todas as telas da versão web.
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.drawer, isNotNull);

    final estado = tester.state<ScaffoldState>(find.byType(Scaffold).first);
    estado.openDrawer();
    await tester.pumpAndSettle();

    for (final titulo in const [
      'Matriz de Treinamentos',
      'EPIs',
      'Cadastramentos',
      'Importação em Massa',
      'Ajuda e Suporte',
      'Configurações',
    ]) {
      expect(find.text(titulo), findsWidgets, reason: 'faltou $titulo no menu');
    }
  });

  testWidgets('MainScreen do colaborador mostra só as telas do perfil', (tester) async {
    HttpOverrides.global = _OverridesFalso();
    SharedPreferences.setMockInitialValues({});

    final auth = AuthService();
    await auth.entrar('colaborador', 'colaborador');
    expect(auth.ehAdmin, isFalse);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.tema, home: MainScreen(auth: auth)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final estado = tester.state<ScaffoldState>(find.byType(Scaffold).first);
    estado.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Área do Colaborador'), findsWidgets);
    expect(find.text('Ajuda e Suporte'), findsWidgets);
    expect(find.text('Configurações'), findsNothing);
    expect(find.text('Colaboradores'), findsNothing);
  });
}

class _OverridesFalso extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _ClienteFalso();
}
