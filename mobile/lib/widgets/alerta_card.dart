import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/indicador.dart';

class AlertaCard extends StatelessWidget {
  final List<AlertaIndicador> alertas;
  const AlertaCard({super.key, required this.alertas});

  Color _cor(String c) => c == 'alta'
      ? AppCores.vencido
      : c == 'media' ? AppCores.vencendo : AppCores.valido;

  @override
  Widget build(BuildContext context) {
    final abertos = alertas.where((a) => a.criticidade != 'baixa').toList();

    return CartaoSgsst(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('⚠️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Precisa de atenção',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                          letterSpacing: -0.2, color: AppCores.petroleo)),
                    Text(
                      abertos.isEmpty
                          ? 'Nenhuma pendência aberta no momento'
                          : '${abertos.length} ${abertos.length == 1 ? "pendência aberta" : "pendências abertas"}',
                      style: const TextStyle(fontSize: 12.5, color: AppCores.cinza),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),
            if (alertas.isEmpty)
              const Text('Nenhuma pendência registrada pelos indicadores.',
                  style: TextStyle(fontSize: 12.5, color: AppCores.cinza))
            else
              ...alertas.map((a) {
                final cor = _cor(a.criticidade);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Container(width: 8, height: 8,
                          decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.mensagem,
                                style: const TextStyle(fontSize: 13.5,
                                  fontWeight: FontWeight.w600, color: AppCores.petroleo)),
                            Text(a.tipo,
                                style: const TextStyle(fontSize: 11.5, color: AppCores.cinza)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}