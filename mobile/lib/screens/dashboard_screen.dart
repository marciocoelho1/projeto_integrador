import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../models/indicador.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../widgets/kpi_card.dart';
import '../widgets/alerta_card.dart';
import '../widgets/conformidade_card.dart';

class DashboardScreen extends StatefulWidget {
  final AuthService auth;
  const DashboardScreen({super.key, required this.auth});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardService _service = DashboardService(widget.auth);
  Future<Indicadores>? _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _service.carregar();
  }

  Future<void> _recarregar() async {
    setState(() => _futuro = _service.carregar());
    await _futuro;
  }

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
          children: const [
            Text('Meu SGSST',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            Text('Indicadores de SST',
                style: TextStyle(fontSize: 12.5, color: Color(0xB3FFFFFF))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await widget.auth.sair();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: FutureBuilder<Indicadores>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${snap.error}', textAlign: TextAlign.center,
                        style: const TextStyle(color: AppCores.vencido)),
                    const SizedBox(height: 16),
                    OutlinedButton(onPressed: _recarregar, child: const Text('Tentar novamente')),
                  ],
                ),
              ),
            );
          }

          final d = snap.data!;
          final hora = DateFormat('dd/MM/yyyy HH:mm').format(d.geradoEm);

          return RefreshIndicator(
            onRefresh: _recarregar,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text('Visão geral', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 4),
                Text('Atualizado em $hora',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 14),

                // Bloco 1 — KPIs em grade 2x2
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    KpiCard(
                      rotulo: 'Colaboradores ativos',
                      valor: '${d.colaboradores.ativos}',
                      sufixo: '/ ${d.colaboradores.total}',
                      dica: '${d.colaboradores.afastados} afastados',
                      cor: AppCores.petroleo,
                    ),
                    KpiCard(
                      rotulo: 'EPIs em estoque',
                      valor: '${d.epis.emEstoque}',
                      sufixo: 'un.',
                      dica: '${d.epis.vencidos} vencidas',
                      cor: AppCores.vencido,
                    ),
                    KpiCard(
                      rotulo: 'Certificações',
                      valor: '${d.certificacoes.ativas}',
                      sufixo: 'ativas',
                      dica: '${d.certificacoes.vencendoEm30Dias} a vencer',
                      cor: AppCores.vencendo,
                    ),
                    KpiCard(
                      rotulo: 'EPIs entregues',
                      valor: '${d.epis.entreguesUltimos30Dias}',
                      sufixo: '30 dias',
                      dica: '${d.epis.totalTipos} tipos',
                      cor: AppCores.cinza,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bloco 2 — Conformidade de treinamentos
                ConformidadeCard(treinamentos: d.treinamentos),
                const SizedBox(height: 12),

                // Bloco 3 — Precisa de atenção
                AlertaCard(alertas: d.alertas),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}