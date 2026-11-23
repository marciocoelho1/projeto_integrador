import 'package:flutter/material.dart';
import 'src/screens/epis_screen.dart';

void main() {
  runApp(const ControleEpisApp());
}

class ControleEpisApp extends StatelessWidget {
  const ControleEpisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Controle de EPIs',
      home: EpisScreen(),
    );
  }
}
