import 'package:flutter/material.dart';

import 'app_theme.dart';

enum ToastTipo { sucesso, erro, aviso }

/// Substituto do `ToastService` do web: mesmo canal (mensagem no rodapé) com
/// o visual do dashboard mobile.
class Toast {
  static void sucesso(BuildContext context, String mensagem) =>
      _mostrar(context, mensagem, ToastTipo.sucesso);

  static void erro(BuildContext context, String mensagem) =>
      _mostrar(context, mensagem, ToastTipo.erro);

  static void aviso(BuildContext context, String mensagem) =>
      _mostrar(context, mensagem, ToastTipo.aviso);

  static void _mostrar(BuildContext context, String mensagem, ToastTipo tipo) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            mensagem,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: switch (tipo) {
            ToastTipo.sucesso => AppCores.valido,
            ToastTipo.erro => AppCores.vencido,
            ToastTipo.aviso => AppCores.vencendo,
          },
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }
}
