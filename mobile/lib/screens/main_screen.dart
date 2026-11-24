import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  final AuthService auth;
  const MainScreen({super.key, required this.auth});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    // Destinos dos colegas entram aqui: substitua _EmConstrucao pela tela deles.
    final telas = [
      DashboardScreen(auth: widget.auth),
      const _EmConstrucao('Treinamentos'),
      const _EmConstrucao('EPIs'),
      const _EmConstrucao('Perfil'),
    ];

    return Scaffold(
      body: telas[_indice],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        backgroundColor: Colors.white,
        indicatorColor: AppCores.petroleo.withValues(alpha: 0.10),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), label: 'Painel'),
          NavigationDestination(icon: Icon(Icons.workspace_premium_outlined), label: 'Treinamentos'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), label: 'EPIs'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _EmConstrucao extends StatelessWidget {
  final String titulo;
  const _EmConstrucao(this.titulo);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppCores.petroleo,
        foregroundColor: Colors.white,
        title: Text(titulo),
      ),
      body: Center(
        child: Text('$titulo — em construção',
            style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}