import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/balao_ajuda.dart';
import 'ajuda_suporte_screen.dart';
import 'login_screen.dart';
import 'ajuda_suporte_colaborador_screen.dart';
import 'menu_sgsst.dart';

/// Casca autenticada do app.
///
/// A navegacao tem dois niveis, como no web: a barra inferior traz os quatro
/// atalhos do perfil, e uma grade "Todas as telas" fica no topo de cada aba (e
/// tambem no menu lateral) para as demais telas ficarem alcancaveis sem gesto.
/// O baleao de ajuda acompanha todas as abas.
///
/// A tela exibida e guardada pelo TITULO, e nao por indice: a barra inferior
/// mostra um subconjunto do menu, entao um indice do menu completo apontaria
/// para a tela errada (era o bug em que "Matriz de Treinamentos" abria
/// "Colaboradores" e as ultimas telas caiam todas em "Configuracoes").
class MainScreen extends StatefulWidget {
  final AuthService auth;
  const MainScreen({super.key, required this.auth});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _tituloAtual = '';
  final GlobalKey<CascaComAjudaState> _chaveCasca = GlobalKey<CascaComAjudaState>();
  final GlobalKey<ScaffoldState> _chaveScaffold = GlobalKey<ScaffoldState>();

  List<ItemMenuSgsst> get _barra => itensDaBarra(widget.auth);
  List<ItemMenuSgsst> get _foraDaBarra => itensForaDaBarra(widget.auth);

  @override
  void initState() {
    super.initState();
    _tituloAtual = _barra.isEmpty ? '' : _barra.first.titulo;
  }

  Future<void> _sair() async {
    // Fecha o menu lateral antes de trocar a rota. Sem isso o Navigator.pop do
    // drawer consome a troca e o app fica na mesma tela, ja sem sessao — era o
    // bug em que "Sair" deixava o colaborador logado na Area do Colaborador.
    final navigator = Navigator.of(context);
    final scaffold = _chaveScaffold.currentState;
    if (scaffold?.isDrawerOpen ?? false) {
      scaffold!.closeDrawer();
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    await widget.auth.sair();
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(auth: widget.auth),
        settings: const RouteSettings(name: '/'),
      ),
      (rota) => false,
    );
  }

  /// Abre a tela pelo titulo, venha ela do menu lateral, do seletor de telas ou
  /// de um link dentro de outro bloco.
  void _abrirPorTitulo(String titulo) {
    final existe = menuDoPerfil(widget.auth).any((i) => i.titulo == titulo);
    if (!existe) return;

    if (_chaveScaffold.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    if (!mounted) return;
    setState(() => _tituloAtual = titulo);
    _chaveCasca.currentState?.sinalizarNavegacao();
  }

  void _abrirAjuda() {
    final tela = widget.auth.ehAdmin
        ? AjudaSuporteScreen(auth: widget.auth) as Widget
        : AjudaSuporteColaboradorScreen(auth: widget.auth) as Widget;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
  }

  @override
  Widget build(BuildContext context) {
    final barra = _barra;
    if (barra.isEmpty) {
      return const Scaffold(body: SizedBox.shrink());
    }

    // Se o titulo atual nao estiver na barra (tela do seletor), nenhum destino
    // fica marcado; ao voltar para um atalho, ele volta a acender.
    final indiceNaBarra = barra.indexWhere((i) => i.titulo == _tituloAtual);
    final foraDaBarra = _foraDaBarra;
    final itemAtual = menuDoPerfil(widget.auth)
        .where((i) => i.titulo == _tituloAtual)
        .firstOrNull;

    return Scaffold(
      key: _chaveScaffold,
      drawer: _MenuLateral(
        itens: menuDoPerfil(widget.auth),
        tituloAtual: _tituloAtual,
        auth: widget.auth,
        aoSelecionar: (item) => _abrirPorTitulo(item.titulo),
        aoSair: _sair,
      ),
      body: CascaComAjuda(
        key: _chaveCasca,
        gatilhoDeNavegacao: _tituloAtual,
        aoAbrirAjuda: _abrirAjuda,
        child: Column(
          children: [
            _CabecalhoAba(
              titulo: _tituloAtual,
              subtitulo: subtituloDaTela(_tituloAtual),
              demais: foraDaBarra,
              // O botao de voltar so aparece quando a tela veio do seletor:

              aoVoltar: indiceNaBarra < 0 ? () => _abrirPorTitulo(barra.first.titulo) : null,
              aoAbrirMenu: () => _chaveScaffold.currentState?.openDrawer(),
              aoEscolher: _abrirPorTitulo,
            ),
            Expanded(
              child: itemAtual == null
                  ? const SizedBox.shrink()
                  : itemAtual.construir(widget.auth, aoNavegar: _abrirPorTitulo),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indiceNaBarra < 0 ? 0 : indiceNaBarra,
        onDestinationSelected: (i) => _abrirPorTitulo(barra[i].titulo),
        backgroundColor: Colors.white,
        indicatorColor: AppCores.petroleo.withValues(alpha: 0.10),
        destinations: [
          for (final item in barra)
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

/// Cabecalho fixo da aba: menu, titulo, voltar (quando fora da barra) e o
/// seletor "Todas as telas".
class _CabecalhoAba extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final List<ItemMenuSgsst> demais;
  final VoidCallback aoAbrirMenu;
  final VoidCallback? aoVoltar;
  final ValueChanged<String> aoEscolher;

  const _CabecalhoAba({
    required this.titulo,
    this.subtitulo,
    required this.demais,
    required this.aoAbrirMenu,
    required this.aoEscolher,
    this.aoVoltar,
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
              if (aoVoltar != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Voltar',
                  onPressed: aoVoltar,
                )
              else
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  tooltip: 'Menu',
                  onPressed: aoAbrirMenu,
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitulo != null)
                      Text(
                        subtitulo!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xB3FFFFFF),
                          fontSize: 11.5,
                        ),
                      ),
                  ],
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
                      key: ValueKey('menu-${item.titulo}'),
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
