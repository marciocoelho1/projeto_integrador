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
    this.embutido = false,
  });

  final String titulo;
  final String? subtitulo;
  final Widget child;
  final Widget? acao;
  final List<Widget>? acoes;
  final Widget? floatingActionButton;

  /// Quando a tela aparece dentro da casca (`MainScreen`), quem desenha o
  /// titulo, o botao de menu e as acoes e o cabecalho da casca. Nesse caso o
  /// scaffold devolve so o corpo, mais o FAB — antes as duas barras apareciam
  /// empilhadas e o titulo era repetido ao lado do menu.
  final bool embutido;

  @override
  Widget build(BuildContext context) {
    if (embutido) {
      // Barra de acoes propria da tela, abaixo do cabecalho da casca: mantem
      // "Cadastrar" e "Exportar" acessiveis sem repetir titulo nem menu.
      final temAcoes = acao != null || (acoes?.isNotEmpty ?? false);
      return Scaffold(
        backgroundColor: AppCores.areia,
        floatingActionButton: floatingActionButton,
        body: Column(
          children: [
            if (temAcoes)
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [?acao, ...?acoes],
                ),
              ),
            if (temAcoes) const Divider(height: 1, color: AppCores.hairline),
            Expanded(child: child),
          ],
        ),
      );
    }
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
