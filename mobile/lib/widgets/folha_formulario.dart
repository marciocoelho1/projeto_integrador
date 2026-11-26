import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Formulario em folha (cadastro, edicao e detalhes).
///
/// Antes cada modal desenhava so a alca de arrastar e o titulo em texto solto:
/// ao abrir um cadastro, o botao de menu desaparecia e a tela nao dizia em que
/// modulo o usuario estava. Agora o formulario tem a mesma barra das telas —
/// fundo petroleo, titulo, subtitulo, fechar a esquerda e a acao a direita —,
/// entao o padrao se mantem ao entrar e sair do cadastro.
class FolhaFormulario extends StatelessWidget {
  const FolhaFormulario({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acao,
    required this.children,
    this.tamanhoInicial = 0.9,
  });

  final String titulo;
  final String? subtitulo;

  /// Acao no canto direito da barra (ex.: Salvar).
  final Widget? acao;

  /// Conteudo rolavel do formulario.
  final List<Widget> children;

  final double tamanhoInicial;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: tamanhoInicial,
      maxChildSize: 0.96,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          Material(
            color: AppCores.petroleo,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (subtitulo != null)
                            Text(
                              subtitulo!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xB3FFFFFF),
                                fontSize: 11.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ?acao,
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppCores.areia,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}