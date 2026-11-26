import 'package:flutter/material.dart';

const _petroleo = Color(0xFF0B3B4A);
const _areia = Color(0xFFF6F1E7);
const _cartao = Colors.white;
const _secundario = Color(0xFF5A6B70);
const _verde = Color(0xFF1B7F5A);
const _amarelo = Color(0xFFB8860B);
const _vermelho = Color(0xFFB3392F);
const _abasSistema = ['Usuários do Sistema', 'Grupos de Usuários', 'Matriz de Acessos', 'Configurações Globais', 'Logs de Auditoria'];

class _Usuario {
  _Usuario(this.nome, this.email, this.documento, this.grupo, this.ativo);
  String nome, email, documento, grupo;
  bool ativo;
}

class _Grupo {
  _Grupo(this.nome, this.finalidade, this.modulos);
  String nome, finalidade;
  List<String> modulos;
}

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  final _abas = _abasSistema;
  int _aba = 0;
  String _busca = '';
  String _grupoSelecionado = 'Administradores';
  final _usuarios = <_Usuario>[
    _Usuario('Joana Ribeiro de Souza', 'joana.souza@essenza.com.br', '1042', 'Operacional', true),
    _Usuario('Marcos Oliveira', 'marcos.oliveira@essenza.com.br', '1088', 'Administradores', true),
    _Usuario('Ana Beatriz Lima', 'ana.lima@essenza.com.br', '1120', 'Operacional', false),
  ];
  final _grupos = <_Grupo>[
    _Grupo('Administradores', 'Acesso completo às configurações e módulos do SGSST.', ['Painel', 'Usuários', 'Treinamentos', 'EPIs', 'Relatórios', 'Configurações']),
    _Grupo('Operacional', 'Acesso às rotinas operacionais de segurança do trabalho.', ['Painel', 'Treinamentos', 'EPIs']),
    _Grupo('Gestores', 'Acompanhamento de indicadores, equipes e relatórios.', ['Painel', 'Treinamentos', 'Relatórios']),
  ];
  final _modulos = ['Painel', 'Usuários', 'Treinamentos', 'EPIs', 'Relatórios', 'Configurações'];
  final _regras = <String, bool>{
    'Alertar vencimento de treinamentos': true,
    'Bloquear entrega de EPI com CA vencido': true,
    'Notificar gestores sobre pendências': false,
    'Enviar lembretes automáticos': true,
  };
  final _parametros = <String, String>{
    'Antecedência de alerta (dias)': '30',
    'Tentativas de acesso': '5',
    'Tempo de sessão (minutos)': '60',
  };
  final _logs = [
    ['26/11/2026 13:42', 'Joana Ribeiro', 'Usuários', 'ACESSO', 'Consultou cadastro de usuários'],
    ['26/11/2026 12:18', 'Marcos Oliveira', 'Configurações', 'EDICAO', 'Atualizou parâmetros globais'],
    ['25/11/2026 16:05', 'Ana Beatriz', 'EPIs', 'CRIACAO', 'Registrou entrega de EPI'],
  ];

  List<_Usuario> get _usuariosFiltrados => _usuarios.where((u) =>
      '${u.nome} ${u.email} ${u.documento} ${u.grupo} ${u.ativo ? "ativo" : "inativo"}'
          .toLowerCase().contains(_busca.toLowerCase())).toList();

  void _mensagem(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _petroleo,
        foregroundColor: Colors.white,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Meu SGSST', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
          Text('Administração do sistema', style: TextStyle(fontSize: 12, color: Color(0xFFD0E0E3))),
        ]),
        actions: [
          if (wide) const Padding(
            padding: EdgeInsets.only(right: 24),
            child: Center(child: Text('AMBIENTE ADMINISTRATIVO', style: TextStyle(fontSize: 11, letterSpacing: 1.1))),
          ),
        ],
      ),
      drawer: wide ? null : Drawer(
        child: SafeArea(child: Column(children: [
          const _DrawerHeader(),
          Expanded(child: ListView.builder(
            itemCount: _abas.length,
            itemBuilder: (_, i) => ListTile(
              selected: _aba == i,
              leading: Icon(_icons[i]),
              title: Text(_abas[i]),
              onTap: () { setState(() => _aba = i); Navigator.pop(context); },
            ),
          )),
        ])),
      ),
      body: Row(children: [
        if (wide) _Sidebar(selected: _aba, onSelect: (i) => setState(() => _aba = i)),
        Expanded(child: SafeArea(
          child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Padding(
              padding: EdgeInsets.all(wide ? 28 : 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('SGSST / Administração', style: TextStyle(color: _secundario.withOpacity(.9), fontSize: 12)),
                    const SizedBox(height: 5),
                    Text('Configurações do Sistema', style: TextStyle(fontSize: wide ? 29 : 23, fontWeight: FontWeight.w800, color: _petroleo)),
                  ])),
                  if (wide) FilledButton.icon(
                    onPressed: _novoUsuario,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Cadastrar usuário'),
                  ),
                ]),
                const SizedBox(height: 22),
                if (wide) _TabBar(abas: _abas, selected: _aba, onSelect: (i) => setState(() => _aba = i))
                else Row(children: [
                  Expanded(child: DropdownButtonFormField<int>(
                    value: _aba,
                    decoration: const InputDecoration(labelText: 'Área de configuração'),
                    items: List.generate(_abas.length, (i) => DropdownMenuItem(value: i, child: Text(_abas[i], overflow: TextOverflow.ellipsis))),
                    onChanged: (v) { if (v != null) setState(() => _aba = v); },
                  )),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Cadastrar usuário',
                    onPressed: _novoUsuario,
                    icon: const Icon(Icons.person_add_alt_1),
                  ),
                ]),
                const SizedBox(height: 20),
                Expanded(child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _conteudo(wide),
                )),
              ]),
            ),
          )),
        )),
      ]),
    );
  }

  Widget _conteudo(bool wide) {
    switch (_aba) {
      case 0: return _usuariosView(wide);
      case 1: return _gruposView(wide);
      case 2: return _matrizView(wide);
      case 3: return _globaisView();
      default: return _logsView(wide);
    }
  }

  Widget _usuariosView(bool wide) => _CardPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      const Expanded(child: _SectionTitle('Gestão de Usuários')),
      SizedBox(width: wide ? 360 : 190, child: TextField(
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar usuário'),
        onChanged: (v) => setState(() => _busca = v),
      )),
    ]),
    const SizedBox(height: 14),
    if (wide) Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
      columns: const [DataColumn(label: Text('USUÁRIO')), DataColumn(label: Text('CPF / MATRÍCULA')), DataColumn(label: Text('GRUPO')), DataColumn(label: Text('STATUS')), DataColumn(label: Text('AÇÕES'))],
      rows: _usuariosFiltrados.map((u) => DataRow(cells: [
        DataCell(SizedBox(width: 230, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(u.nome, style: const TextStyle(fontWeight: FontWeight.w700)), Text(u.email, style: const TextStyle(fontSize: 11, color: _secundario))]))),
        DataCell(Text(u.documento)),
        DataCell(_Badge(u.grupo, color: const Color(0xFFE7EEF0), textColor: _petroleo)),
        DataCell(_Badge(u.ativo ? 'Ativo' : 'Inativo', color: u.ativo ? const Color(0xFFE3F3EC) : const Color(0xFFFBE8E6), textColor: u.ativo ? _verde : _vermelho)),
        DataCell(TextButton(onPressed: () => _editarUsuario(u), child: const Text('Editar'))),
      ])).toList(),
    )))
    else Expanded(child: ListView(children: _usuariosFiltrados.map((u) => _UserTile(user: u, onEdit: () => _editarUsuario(u))).toList())),
  ]));

  Widget _gruposView(bool wide) => LayoutBuilder(builder: (context, c) {
    final columns = c.maxWidth > 850 ? 3 : c.maxWidth > 560 ? 2 : 1;
    return GridView.count(
      crossAxisCount: columns, mainAxisSpacing: 14, crossAxisSpacing: 14,
      childAspectRatio: wide ? 1.5 : 1.7,
      children: _grupos.map((g) => _CardPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(g.nome, style: const TextStyle(color: _petroleo, fontSize: 18, fontWeight: FontWeight.w800))), _Badge('${g.modulos.length} módulos', color: const Color(0xFFE7EEF0), textColor: _petroleo)]),
        const SizedBox(height: 12),
        Expanded(child: Text(g.finalidade, style: const TextStyle(color: _secundario))),
        OutlinedButton.icon(onPressed: () { setState(() { _grupoSelecionado = g.nome; _aba = 2; }); }, icon: const Icon(Icons.tune), label: const Text('Ajustar matriz')),
      ]))).toList(),
    );
  });

  Widget _matrizView(bool wide) {
    final grupo = _grupos.firstWhere((g) => g.nome == _grupoSelecionado, orElse: () => _grupos.first);
    return _CardPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: _SectionTitle('Matriz de Permissões')),
        SizedBox(width: wide ? 260 : 170, child: DropdownButtonFormField<String>(
          value: grupo.nome, decoration: const InputDecoration(labelText: 'Grupo'),
          items: _grupos.map((g) => DropdownMenuItem(value: g.nome, child: Text(g.nome))).toList(),
          onChanged: (v) { if (v != null) setState(() => _grupoSelecionado = v); },
        )),
      ]),
      const SizedBox(height: 12),
      Container(width: double.infinity, padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xFFEAF0EF), borderRadius: BorderRadius.circular(8), border: const Border(left: BorderSide(color: _petroleo, width: 4))), child: Text('Você está editando as regras para: ${grupo.nome}', style: const TextStyle(color: _petroleo))),
      const SizedBox(height: 8),
      Expanded(child: ListView(children: _modulos.map((m) => SwitchListTile(
        value: grupo.modulos.contains(m), activeColor: _petroleo, title: Text(m, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('Permitir acesso ao módulo $m'),
        onChanged: (v) => setState(() { v ? grupo.modulos.add(m) : grupo.modulos.remove(m); }),
      )).toList())),
    ]));
  }

  Widget _globaisView() => _CardPanel(child: ListView(padding: EdgeInsets.zero, children: [
    const _SectionTitle('Regras de Negócio e Alertas'),
    const SizedBox(height: 4),
    const Text('Configure o comportamento autônomo do sistema SST.', style: TextStyle(color: _secundario)),
    const SizedBox(height: 12),
    ..._regras.entries.map((e) => SwitchListTile(
      contentPadding: EdgeInsets.zero, title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
      value: e.value, activeColor: _petroleo,
      onChanged: (v) => setState(() => _regras[e.key] = v),
    )),
    const Divider(height: 28),
    const _SectionTitle('Parâmetros globais'),
    ..._parametros.entries.map((e) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: e.value, keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: e.key),
        onChanged: (v) => _parametros[e.key] = v,
      ),
    )),
    const SizedBox(height: 14),
    Align(alignment: Alignment.centerRight, child: FilledButton.icon(
      onPressed: () => _mensagem('Configurações atualizadas nesta demonstração. Conecte o serviço da API para persistir os dados.'),
      icon: const Icon(Icons.save), label: const Text('Salvar configurações'),
    )),
  ]));

  Widget _logsView(bool wide) => _CardPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const _SectionTitle('Histórico de Auditoria'),
    const SizedBox(height: 14),
    Expanded(child: ListView.separated(
      itemCount: _logs.length, separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (_, i) {
        final l = _logs[i];
        return ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(backgroundColor: Color(0xFFE7EEF0), child: Icon(Icons.history, color: _petroleo)),
          title: Text('${l[3]} · ${l[2]}', style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${l[0]}  •  ${l[1]}\\n${l[4]}'),
          isThreeLine: true,
        );
      },
    )),
  ]));

  void _novoUsuario() => _abrirFormulario();
  void _editarUsuario(_Usuario usuario) => _abrirFormulario(usuario: usuario);

  void _abrirFormulario({_Usuario? usuario}) {
    final nome = TextEditingController(text: usuario?.nome ?? '');
    final email = TextEditingController(text: usuario?.email ?? '');
    final documento = TextEditingController(text: usuario?.documento ?? '');
    String grupo = usuario?.grupo ?? _grupos.first.nome;
    bool ativo = usuario?.ativo ?? true;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => AlertDialog(
      title: Text(usuario == null ? 'Cadastrar usuário' : 'Editar usuário'),
      content: SizedBox(width: 460, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome completo')),
        const SizedBox(height: 10),
        TextField(controller: email, decoration: const InputDecoration(labelText: 'E-mail corporativo')),
        const SizedBox(height: 10),
        TextField(controller: documento, decoration: const InputDecoration(labelText: 'CPF / Matrícula')),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(value: grupo, decoration: const InputDecoration(labelText: 'Grupo de acesso'), items: _grupos.map((g) => DropdownMenuItem(value: g.nome, child: Text(g.nome))).toList(), onChanged: (v) { if (v != null) setModal(() => grupo = v); }),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Usuário ativo'), value: ativo, onChanged: (v) => setModal(() => ativo = v)),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(onPressed: () {
          if (nome.text.trim().isEmpty || email.text.trim().isEmpty) return;
          setState(() {
            if (usuario == null) {
              _usuarios.add(_Usuario(nome.text.trim(), email.text.trim(), documento.text.trim(), grupo, ativo));
            } else {
              usuario.nome = nome.text.trim(); usuario.email = email.text.trim();
              usuario.documento = documento.text.trim(); usuario.grupo = grupo; usuario.ativo = ativo;
            }
          });
          Navigator.pop(ctx);
          _mensagem('Usuário atualizado na demonstração.');
        }, child: const Text('Salvar')),
      ],
    )));
  }
}

const _icons = [Icons.people_alt_outlined, Icons.groups_outlined, Icons.admin_panel_settings_outlined, Icons.tune, Icons.history];

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(22), color: _petroleo,
    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.shield_outlined, color: Colors.white, size: 34),
      SizedBox(height: 12), Text('Meu SGSST', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      Text('Administração', style: TextStyle(color: Color(0xFFD0E0E3))),
    ]),
  );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => Container(
    width: 250, color: const Color(0xFFFFFFFF),
    child: Column(children: [
      const _DrawerHeader(),
      const SizedBox(height: 12),
      for (var i = 0; i < _abasSistema.length; i++)
        ListTile(
          selected: selected == i, selectedTileColor: const Color(0xFFEAF0EF),
          leading: Icon(_icons[i], color: selected == i ? _petroleo : _secundario),
          title: Text(_abasSistema[i], style: TextStyle(fontSize: 13, fontWeight: selected == i ? FontWeight.w700 : FontWeight.w500, color: selected == i ? _petroleo : _secundario)),
          onTap: () => onSelect(i),
        ),
      const Spacer(),
      const Padding(padding: EdgeInsets.all(16), child: Text('SGSST • Ambiente administrativo', style: TextStyle(fontSize: 11, color: _secundario))),
    ]),
  );
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.abas, required this.selected, required this.onSelect});
  final List<String> abas;
  final int selected;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: List.generate(abas.length, (i) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(abas[i]), selected: selected == i,
        selectedColor: const Color(0xFFDCE9E8),
        labelStyle: TextStyle(color: selected == i ? _petroleo : _secundario, fontWeight: FontWeight.w700),
        onSelected: (_) => onSelect(i),
      ),
    ))),
  );
}

class _CardPanel extends StatelessWidget {
  const _CardPanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: _cartao, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E2D9)), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, 5))]),
    child: child,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: _petroleo, fontSize: 19, fontWeight: FontWeight.w800));
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {required this.color, required this.textColor});
  final String text;
  final Color color, textColor;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(30)),
    child: Text(text, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onEdit});
  final _Usuario user;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE5E2D9))),
    child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(user.nome, style: const TextStyle(color: _petroleo, fontWeight: FontWeight.w800))), IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined))]),
      Text(user.email, style: const TextStyle(color: _secundario, fontSize: 12)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _Badge('Matrícula ${user.documento}', color: const Color(0xFFE7EEF0), textColor: _petroleo),
        _Badge(user.grupo, color: const Color(0xFFE7EEF0), textColor: _petroleo),
        _Badge(user.ativo ? 'Ativo' : 'Inativo', color: user.ativo ? const Color(0xFFE3F3EC) : const Color(0xFFFBE8E6), textColor: user.ativo ? _verde : _vermelho),
      ]),
    ])),
  );
}
