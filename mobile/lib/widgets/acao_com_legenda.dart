import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Acao de tela com legenda (icone + texto).
///
/// Antes as acoes dos modulos eram so um icone, e o significado dependia de
/// manter o dedo pressionado para ver o tooltip. Agora o botao diz o que faz por
/// escrito, com a mesma cor de destaque do app.
class AcaoComLegenda extends StatelessWidget {
  const AcaoComLegenda({
    super.key,
    required this.rotulo,
    required this.icone,
    required this.aoClicar,
  });

  final String rotulo;
  final IconData icone;
  final VoidCallback aoClicar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: AppCores.petroleo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: aoClicar,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone, size: 18, color: AppCores.petroleo),
                const SizedBox(width: 7),
                Text(
                  rotulo,
                  style: const TextStyle(
                    color: AppCores.petroleo,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}