import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/indicador.dart';

class ConformidadeCard extends StatelessWidget {
  final ResumoTreinamentos treinamentos;
  const ConformidadeCard({super.key, required this.treinamentos});

  @override
  Widget build(BuildContext context) {
    final t = treinamentos;
    final emDia = (t.porcentagem / 100).clamp(0.0, 1.0);

    return CartaoSgsst(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Conformidade de treinamentos',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                            letterSpacing: -0.2, color: AppCores.petroleo)),
                      Text('Vínculos com validade em dia',
                          style: TextStyle(fontSize: 12.5, color: AppCores.cinza)),
                    ],
                  ),
                ),
                _selo(t.vencidos),
              ],
            ),
            const SizedBox(height: 12),
            Text('${t.porcentagem}%',
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700,
                  color: AppCores.petroleo)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: emDia, minHeight: 4,
                backgroundColor: AppCores.vencido.withValues(alpha: 0.20),
                valueColor: const AlwaysStoppedAnimation(AppCores.valido),
              ),
            ),
            const SizedBox(height: 10),
            Text('${t.concluidos} de ${t.total} vínculos concluídos · ${t.pendentes} pendentes',
                style: const TextStyle(fontSize: 12.5, color: AppCores.cinza)),
          ],
        ),
      ),
    );
  }

  Widget _selo(int vencidos) {
    final cor = vencidos > 0 ? AppCores.vencido : AppCores.valido;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(vencidos > 0 ? '$vencidos vencidos' : 'Sem vencidos',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: cor)),
      ]),
    );
  }
}