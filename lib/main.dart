import 'package:flutter/material.dart';
import 'ajuda_suporte_screen.dart';

void main() {
  runApp(const AjudaSuporteApp());
}

class AjudaSuporteApp extends StatelessWidget {
  const AjudaSuporteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ajuda e suporte',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B3B4A)),
      ),
      home: const AjudaSuporteScreen(),
    );
  }
}
