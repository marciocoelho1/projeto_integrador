import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Casca padrão das telas internas: AppBar petróleo, título/subtítulo e
/// ação opcional. O dashboard mobile usa esse mesmo desenho.
class SgsstScaffold extends StatelessWidget {
  const SgsstScaffold({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.child,
    this.acao,
    this.acoes,
    this.floatingActionButton,
  });

  final String titulo;
  final String? subtitulo;
  final Widget child;
  final Widget? acao;
  final List<Widget>? acoes;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.areia,
      appBar: AppBar(
        backgroundColor: AppCores.petroleo,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            if (subtitulo != null)
              Text(
                subtitulo!,
                style: const TextStyle(fontSize: 12.5, color: Color(0xB3FFFFFF)),
              ),
          ],
        ),
        actions: [
          ?acao,
          ...?acoes,
        ],
      ),
      floatingActionButton: floatingActionButton,
      body: child,
    );
  }
}
