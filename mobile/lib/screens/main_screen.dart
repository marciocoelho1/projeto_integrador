import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/balao_ajuda.dart';
import 'ajuda_suporte_screen.dart';
import 'ajuda_suporte_colaborador_screen.dart';
import 'menu_sgsst.dart';

/// Casca autenticada do app.
///
/// A navegacao tem dois niveis, como no web: a barra inferior traz os quatro
/// atalhos do perfil, e uma grade "Todas as telas" fica no topo de cada aba (e
/// tambem no menu lateral) para as demais telas ficarem alcancaveis sem gesto.
/// O baleao de ajuda acompanha todas as abas.
class MainScreen extends StatefulWidget {
  final AuthService auth;
  const MainScreen({super.key, required this.auth});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _indice = 0;
  late final List<ItemMenuSgsst> _itens = menuDoPerfil(widget.auth);
  final GlobalKey<CascaComAjudaState> _chaveCasca = GlobalKey<CascaComAjudaState>();
  final GlobalKey<ScaffoldState> _chaveScaffold = GlobalKey<ScaffoldState>();

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

  void _irParaIndice(int indice) {
    if (indice < 0 || indice >= _atalhos.length) return;
    setState(() => _indice = indice);
    _chaveCasca.currentState?.sinalizarNavegacao();
  }

  /// Navegacao por nome, usada pelo menu lateral e pelo grid de telas.
  void _abrirPorTitulo(String titulo) {
    final indice = _itens.indexWhere((i) => i.titulo == titulo);
    if (indice < 0) return;
    if (_chaveScaffold.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    _irParaIndice(indice);
  }

  void _abrirAjuda() {
    final tela = widget.auth.ehAdmin
        ? AjudaSuporteScreen(auth: widget.auth) as Widget
        : AjudaSuporteColaboradorScreen(auth: widget.auth) as Widget;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
  }

  @override
  Widget build(BuildContext context) {
    final atalhos = _atalhos;
    if (atalhos.isEmpty) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final indiceSeguro = _indice.clamp(0, atalhos.length - 1);
    final atual = atalhos[indiceSeguro];

    // O grid lista as telas que NAO estao na barra inferior, para nao duplicar.
    final demais = _itens.where((i) => !atalhos.any((a) => a.titulo == i.titulo)).toList();

    return Scaffold(
      key: _chaveScaffold,
      drawer: _MenuLateral(
        itens: _itens,
        tituloAtual: atual.titulo,
        auth: widget.auth,
        aoSelecionar: (item) => _abrirPorTitulo(item.titulo),
        aoSair: _sair,
      ),
      body: CascaComAjuda(
        key: _chaveCasca,
        gatilhoDeNavegacao: indiceSeguro,
        aoAbrirAjuda: _abrirAjuda,
        child: Column(
          children: [
            // Cabecalho da aba: identifica a tela e da acesso ao menu e as demais telas.
            _CabecalhoAba(
              titulo: atual.titulo,
              demais: demais,
              aoAbrirMenu: () => _chaveScaffold.currentState?.openDrawer(),
              aoEscolher: _abrirPorTitulo,
            ),
            Expanded(child: atual.construir(widget.auth, aoNavegar: _abrirPorTitulo)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indiceSeguro,
        onDestinationSelected: _irParaIndice,
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

/// Cabeçalho fixo da aba: botão de menu, título e o seletor "Todas as telas".
class _CabecalhoAba extends StatelessWidget {
  final String titulo;
  final List<ItemMenuSgsst> demais;
  final VoidCallback aoAbrirMenu;
  final ValueChanged<String> aoEscolher;

  const _CabecalhoAba({
    required this.titulo,
    required this.demais,
    required this.aoAbrirMenu,
    required this.aoEscolher,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppCores.petroleo,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 6),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                tooltip: 'Menu',
                onPressed: aoAbrirMenu,
              ),
              Expanded(
                child: Text(
                  titulo,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (demais.isNotEmpty)
                PopupMenuButton<String>(
                  tooltip: 'Todas as telas',
                  icon: const Icon(Icons.apps, color: Colors.white),
                  onSelected: aoEscolher,
                  itemBuilder: (_) => [
                    for (final item in demais)
                      PopupMenuItem(
                        value: item.titulo,
                        child: Row(
                          children: [
                            Icon(item.icone, size: 19, color: AppCores.petroleo),
                            const SizedBox(width: 12),
                            Text(item.titulo),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
                    child: Text(
                      'TELAS DO SISTEMA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppCores.cinza,
                      ),
                    ),
                  ),
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
