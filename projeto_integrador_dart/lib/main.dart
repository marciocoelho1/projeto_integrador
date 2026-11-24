import 'package:flutter/material.dart';

void main() {
  runApp(const SstApp());
}

class SstApp extends StatelessWidget {
  const SstApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema de Gestão de SST',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A5F),
        ),
        fontFamily: 'sans-serif',
      ),
      home: const CollaboratorHomePage(),
    );
  }
}

class CollaboratorHomePage extends StatelessWidget {
  const CollaboratorHomePage({super.key});

  static const Color navy = Color(0xFF071B36);
  static const Color background = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFCBD5E1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // ========================================================
      // APP BAR MOBILE
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        titleSpacing: 16,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sistema de Gestão de SST',
              style: TextStyle(
                color: navy,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Essenza Supermercados Ltda.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
              ),
            ),
          ],
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Ajuda',
              onPressed: () {
                _showHelp(context);
              },
              icon: const Icon(
                Icons.help_outline,
                color: navy,
              ),
            ),
          ),
        ],
      ),

      // ========================================================
      // MENU INFERIOR
      // ========================================================

      bottomNavigationBar: const _BottomNavigation(),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(
            16,
            20,
            16,
            30,
          ),

          child: const _DashboardContent(),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: navy,
        foregroundColor: Colors.white,

        tooltip: 'Ajuda',

        onPressed: () {
          _showHelp(context);
        },

        child: const Icon(
          Icons.support_agent,
        ),
      ),
    );
  }

  static void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,

      showDragHandle: true,

      backgroundColor: Colors.white,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),

      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              10,
              24,
              30,
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                const Icon(
                  Icons.support_agent,
                  size: 45,
                  color: navy,
                ),

                const SizedBox(height: 12),

                const Text(
                  'Ajuda e Suporte',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Entre em contato com o setor responsável caso tenha dúvidas sobre treinamentos, certificações ou EPIs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },

                    icon: const Icon(
                      Icons.chat_outlined,
                    ),

                    label: const Text(
                      'Entrar em contato',
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(
                        double.infinity,
                        48,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// CONTEÚDO PRINCIPAL
// ============================================================

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [
        const _RoleBadge(),

        const SizedBox(height: 22),

        const Text(
          'SGSST / Portal do Colaborador',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Minha Área',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: CollaboratorHomePage.navy,
          ),
        ),

        const SizedBox(height: 20),

        const _StatsGrid(),

        const SizedBox(height: 20),

        const _CertificatesCard(),

        const SizedBox(height: 20),

        const _MaterialsCard(),

        const SizedBox(height: 20),

        const _EpiCard(),

        const SizedBox(height: 25),

       // const _LogoutButton(),
      ],
    );
  }
}

// ============================================================
// BADGE
// ============================================================

class _RoleBadge extends StatelessWidget {
  const _RoleBadge();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,

      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),

        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(8),
        ),

        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Colaborador',
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFF64748B),
              ),
            ),

            Text(
              'COLABORADOR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: CollaboratorHomePage.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ESTATÍSTICAS
// ============================================================

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _StatCard(
          icon: Icons.workspace_premium_outlined,
          title: 'Certificações',
          subtitle: 'Concluídas e registradas',
          value: '1',
        ),

        SizedBox(height: 12),

        _StatCard(
          icon: Icons.menu_book_outlined,
          title: 'Reciclagens',
          subtitle: 'Materiais pendentes',
          value: '1',
        ),

        SizedBox(height: 12),

        _StatCard(
          icon: Icons.health_and_safety_outlined,
          title: 'EPIs Recebidos',
          subtitle: 'Equipamentos em sua posse',
          value: '0',
        ),
      ],
    );
  }
}

// ============================================================
// CARD DE ESTATÍSTICA
// ============================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(
          color: CollaboratorHomePage.border,
        ),

        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,

            decoration: BoxDecoration(
              color: const Color(0xFFE8EDF4),
              borderRadius: BorderRadius.circular(10),
            ),

            child: Icon(
              icon,
              color: CollaboratorHomePage.navy,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: CollaboratorHomePage.navy,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: CollaboratorHomePage.navy,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CERTIFICAÇÕES
// ============================================================

class _CertificatesCard extends StatelessWidget {
  const _CertificatesCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const _PanelTitle(
            icon: Icons.workspace_premium_outlined,
            title: 'Minhas Certificações',
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,

            padding: const EdgeInsets.all(14),

            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CollaboratorHomePage.border,
              ),
            ),

            child: const Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'NR-35 Trabalho em Altura',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CollaboratorHomePage.navy,
                  ),
                ),

                SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: Color(0xFF64748B),
                    ),

                    SizedBox(width: 6),

                    Text(
                      'Validade: 10/07/2026',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 14),

                ClipRRect(
                  borderRadius: BorderRadius.all(
                    Radius.circular(10),
                  ),

                  child: LinearProgressIndicator(
                    value: .82,
                    minHeight: 8,
                    backgroundColor:
                        Color(0xFFE2E8F0),
                    valueColor:
                        AlwaysStoppedAnimation(
                      Color(0xFF64748B),
                    ),
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  '82% do período de validade',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MATERIAIS
// ============================================================

class _MaterialsCard extends StatelessWidget {
  const _MaterialsCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const _PanelTitle(
            icon: Icons.menu_book_outlined,
            title: 'Materiais de Reciclagem',
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,

            padding: const EdgeInsets.all(14),

            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CollaboratorHomePage.border,
              ),
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'NR-35 Trabalho em Altura',

                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CollaboratorHomePage.navy,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius:
                        BorderRadius.circular(8),
                  ),

                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 17,
                        color: Colors.yellow,
                      ),

                      SizedBox(width: 6),

                      Expanded(
                        child: Text(
                          'Prazo de conclusão: 12/06/2026',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.yellow,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(
                    onPressed: () {
                      _openMaterial(context);
                    },

                    icon: const Icon(
                      Icons.open_in_new,
                      size: 17,
                    ),

                    label: const Text(
                      'Acessar material de estudo',
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          CollaboratorHomePage.navy,

                      foregroundColor: Colors.white,

                      minimumSize:
                          const Size(
                        double.infinity,
                        46,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _openMaterial(BuildContext context) {
    showDialog<void>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Material de estudo',
          ),

          content: const Text(
            'Abrindo o material NR-35 Trabalho em Altura.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// EPIs
// ============================================================

class _EpiCard extends StatelessWidget {
  const _EpiCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const _PanelTitle(
            icon: Icons.health_and_safety_outlined,
            title: 'Meus EPIs',
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,

            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CollaboratorHomePage.border,
              ),
            ),

            child: const Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 42,
                  color: Color(0xFF94A3B8),
                ),

                SizedBox(height: 10),

                Text(
                  'Nenhum EPI registrado',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CollaboratorHomePage.navy,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'No momento não existem equipamentos registrados em seu nome.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TÍTULO DOS PAINÉIS
// ============================================================

class _PanelTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _PanelTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 21,
          color: CollaboratorHomePage.navy,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: CollaboratorHomePage.navy,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PAINEL
// ============================================================

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        border: Border.all(
          color: CollaboratorHomePage.border,
        ),

        borderRadius: BorderRadius.circular(12),

        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),

      child: child,
    );
  }
}

// ============================================================
// MENU INFERIOR
// ============================================================

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation();

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      backgroundColor: Colors.white,

      indicatorColor: const Color(0xFFE2E8F0),

      selectedIndex: 0,

      onDestinationSelected: (index) {
        if (index == 1) {
          CollaboratorHomePage._showHelp(context);
        }

        if (index == 2) {
          _showLogout(context);
        }
      },

      destinations: const [
        NavigationDestination(
          icon: Icon(
            Icons.dashboard_outlined,
          ),

          selectedIcon: Icon(
            Icons.dashboard,
          ),

          label: 'Início',
        ),

        NavigationDestination(
          icon: Icon(
            Icons.help_outline,
          ),

          selectedIcon: Icon(
            Icons.help,
          ),

          label: 'Ajuda',
        ),

        NavigationDestination(
          icon: Icon(
            Icons.logout_outlined,
          ),

          selectedIcon: Icon(
            Icons.logout,
          ),

          label: 'Sair',
        ),
      ],
    );
  }

  static void _showLogout(BuildContext context) {
    showDialog<void>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Sair',
          ),

          content: const Text(
            'Deseja realmente encerrar sua sessão?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'Cancelar',
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Sessão encerrada.',
                    ),
                  ),
                );
              },

              child: const Text(
                'Sair',
              ),
            ),
          ],
        );
      },
    );
  }
}