import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class KpiCard extends StatelessWidget {
  final String rotulo, valor, sufixo, dica;
  final Color cor;

  const KpiCard({
    super.key, required this.rotulo, required this.valor,
    required this.sufixo, required this.dica, required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return CartaoSgsst(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(rotulo.toUpperCase(),
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w600,
                  letterSpacing: 0.6, color: AppCores.cinza)),
            RichText(
              text: TextSpan(
                text: valor,
                style: const TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w700,
                  color: AppCores.petroleo, fontFeatures: [FontFeature.tabularFigures()]),
                children: [
                  TextSpan(text: ' $sufixo',
                      style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: AppCores.cinza)),
                ],
              ),
            ),
            Text(dica,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: cor)),
          ],
        ),
      ),
    );
  }
}