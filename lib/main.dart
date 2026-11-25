import 'package:flutter/material.dart';
import 'ajuda_suporte_colaborador_screen.dart';

void main() {
  runApp(const AjudaSuporteColaboradorApp());
}

class AjudaSuporteColaboradorApp extends StatelessWidget {
  const AjudaSuporteColaboradorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ajuda e Suporte - Colaborador',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B3B4A),
        ),
      ),
      home: const AjudaSuporteColaboradorScreen(),
    );
  }
}
