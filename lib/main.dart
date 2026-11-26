import 'package:flutter/material.dart';
import 'features/configuracoes/configuracoes_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SgsstApp());
}

class SgsstApp extends StatelessWidget {
  const SgsstApp({super.key});

  @override
  Widget build(BuildContext context) {
    const petroleum = Color(0xFF0B3B4A);
    return MaterialApp(
      title: 'Meu SGSST',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: petroleum,
          primary: petroleum,
          surface: const Color(0xFFF6F1E7),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F1E7),
        fontFamily: 'Arial',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD8D8D0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD8D8D0)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
      home: const ConfiguracoesPage(),
    );
  }
}
