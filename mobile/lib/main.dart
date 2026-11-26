import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  final auth = AuthService();
  final sessao = await auth.restaurar();

  runApp(MyApp(auth: auth, logado: sessao != null));
}

class MyApp extends StatelessWidget {
  final AuthService auth;
  final bool logado;

  const MyApp({super.key, required this.auth, required this.logado});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu SGSST',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.tema,
      locale: const Locale('pt', 'BR'),
      home: logado ? MainScreen(auth: auth) : LoginScreen(auth: auth),
      // Usado pelo logout (`pushReplacementNamed('/')`) em qualquer tela.
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => LoginScreen(auth: auth),
      ),
    );
  }
}