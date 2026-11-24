import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import 'menu_sgsst.dart';

/// Casca autenticada do app: barra inferior com os atalhos do perfil ativo e
/// um menu lateral com todas as telas da versão web.
class MainScreen extends StatefulWidget {
  final AuthService auth;
  const MainScreen({super.key, required this.auth});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _indice = 0;
  late final List<ItemMenuSgsst> _itens = menuDoPerfil(widget.auth);

  /// Atalhos fixos da barra inferior, derivados do menu do perfil.
  List<ItemMenuSgsst> get _atalhos {
    final preferidos = widget.auth.ehAdmin
        ? const ['Dashboard', 'Colaboradores', 'EPIs', 'Configurações']
        : const ['Área do Colaborador', 'Ajuda e Suporte'];
    return preferidos
        .map((titulo) => _itens.where((i) => i.titulo == titulo).firstOrNull)
        .whereType<ItemMenuSgsst>()
        .toList();
  }

  Future<void> _sair() async {
    await widget.auth.sair();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _abrirDoMenu(ItemMenuSgsst item) {
    final indice = _itens.indexWhere((i) => i.titulo == item.titulo);
    setState(() => _indice = indice < 0 ? 0 : indice);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final atalhos = _atalhos;
    if (atalhos.isEmpty) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final indiceSeguro = _indice.clamp(0, atalhos.length - 1);

    return Scaffold(
      drawer: _MenuLateral(
        itens: _itens,
        tituloAtual: atalhos[indiceSeguro].titulo,
        auth: widget.auth,
        aoSelecionar: _abrirDoMenu,
        aoSair: _sair,
      ),
      body: atalhos[indiceSeguro].construir(widget.auth),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indiceSeguro,
        onDestinationSelected: (i) => setState(() => _indice = i),
        backgroundColor: Colors.white,
        indicatorColor: AppCores.petroleo.withValues(alpha: 0.10),
        destinations: [
          for (final item in atalhos)
            NavigationDestination(icon: Icon(item.icone), label: _rotuloCurto(item.titulo)),
        ],
      ),
    );
  }

  String _rotuloCurto(String titulo) => switch (titulo) {
        'Matriz de Treinamentos' => 'Matriz',
        'Área do Colaborador' => 'Minha área',
        'Ajuda e Suporte' => 'Suporte',
        'Importação em Massa' => 'Importar',
        _ => titulo,
      };
}

class _MenuLateral extends StatelessWidget {
  const _MenuLateral({
    required this.itens,
    required this.tituloAtual,
    required this.auth,
    required this.aoSelecionar,
    required this.aoSair,
  });

  final List<ItemMenuSgsst> itens;
  final String tituloAtual;
  final AuthService auth;
  final ValueChanged<ItemMenuSgsst> aoSelecionar;
  final VoidCallback aoSair;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppCores.areia,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppCores.petroleo,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meu SGSST',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Sistema de Gestão de SST',
                    style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    auth.ehAdmin ? 'Administrador TST' : 'Colaborador',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    auth.sessao?.nomeCompleto ?? '',
                    style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final item in itens)
                    ListTile(
                      leading: Icon(
                        item.icone,
                        color: item.titulo == tituloAtual
                            ? AppCores.petroleo
                            : AppCores.cinza,
                      ),
                      title: Text(
                        item.titulo,
                        style: TextStyle(
                          fontWeight: item.titulo == tituloAtual
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: AppCores.tinta,
                        ),
                      ),
                      selected: item.titulo == tituloAtual,
                      selectedTileColor: AppCores.petroleo.withValues(alpha: 0.08),
                      onTap: () => aoSelecionar(item),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppCores.vencido),
              title: const Text(
                'Sair',
                style: TextStyle(color: AppCores.vencido, fontWeight: FontWeight.w600),
              ),
              onTap: aoSair,
            ),
          ],
        ),
      ),
    );
  }
}
