import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Cartão com cabeçalho e conteúdo, equivalente ao `sst-card` do web.
class CartaoSecao extends StatelessWidget {
  const CartaoSecao({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.child,
    this.acao,
  });

  final String titulo;
  final String? subtitulo;
  final Widget child;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return CartaoSgsst(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                      if (subtitulo != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitulo!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ),
                ),
                ?acao,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Etiqueta de status colorida (equivalente ao `sst-badge`).
class Etiqueta extends StatelessWidget {
  const Etiqueta({super.key, required this.texto, required this.cor});

  final String texto;
  final Color cor;

  /// Cores por status de colaborador.
  factory Etiqueta.colaborador(String status) => Etiqueta(
        texto: status,
        cor: switch (status) {
          'Ativo' => AppCores.valido,
          'Afastado' => AppCores.vencendo,
          _ => AppCores.vencido,
        },
      );

  /// Cores por status de certificação / vínculo / NR.
  factory Etiqueta.situacao(String status) => Etiqueta(
        texto: status,
        cor: switch (status) {
          'Ativa' || 'Concluído' || 'OK' || 'Conforme' || 'Concluída' => AppCores.valido,
          'Alerta' || 'Em Andamento' || 'Pendente' || 'Agendada' => AppCores.vencendo,
          'Vencida' || 'Vencido' || 'Cancelada' => AppCores.vencido,
          _ => AppCores.cinza,
        },
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: cor),
      ),
    );
  }
}

/// Botão de texto usado nas ações de item de lista.
class BotaoTexto extends StatelessWidget {
  const BotaoTexto({
    super.key,
    required this.rotulo,
    required this.aoClicar,
    this.cor,
    this.icone,
  });

  final String rotulo;
  final VoidCallback? aoClicar;
  final Color? cor;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final corFinal = cor ?? AppCores.petroleo;
    return TextButton.icon(
      onPressed: aoClicar,
      icon: icone == null ? const SizedBox.shrink() : Icon(icone, size: 17),
      label: Text(rotulo, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(
        foregroundColor: corFinal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Linha rótulo/valor usada nos detalhes.
class LinhaDetalhe extends StatelessWidget {
  const LinhaDetalhe({super.key, required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(rotulo, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppCores.tinta,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
