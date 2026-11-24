import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatadores.dart';
import '../core/toast.dart';
import '../models/acesso.dart';
import '../models/configuracao.dart';
import '../services/acesso_service.dart';
import '../services/auditoria_service.dart';
import '../services/auth_service.dart';
import '../services/configuracoes_service.dart';
import '../widgets/campo_formulario.dart';
import '../widgets/cartao_secao.dart';
import '../widgets/estado_tela.dart';
import '../widgets/sgsst_scaffold.dart';

const _guias = [
  ('usuarios', 'Usuários', Icons.people_outline),
  ('grupos', 'Grupos', Icons.groups_outlined),
  ('matriz', 'Matriz de Acessos', Icons.grid_view_outlined),
  ('globais', 'Globais', Icons.tune_outlined),
  ('logs', 'Logs', Icons.history),
];

/// Porta de `src/app/tela-configuracoes`: usuários do sistema, grupos, matriz de
/// acessos, configurações globais (regras de alerta + parâmetros) e logs de
/// auditoria.
class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  late final AcessoService _acesso = AcessoService(widget.auth);
  late final AuditoriaService _auditoria = AuditoriaService(widget.auth);
  late final ConfiguracoesService _globais = ConfiguracoesService(widget.auth);

  String _guia = 'usuarios';

  /* ---- Usuários ---- */
  List<UsuarioApi> _usuarios = const [];
  List<GrupoApi> _grupos = const [];
  List<ModuloApi> _modulos = const [];
  final _buscaUsuario = TextEditingController();
  bool _carregandoUsuarios = true;

  /* ---- Grupos / matriz ---- */
  int? _grupoSelecionadoId;

  /* ---- Globais ---- */
  List<RegraAlerta> _regras = const [];
  List<ParametroSistema> _parametros = const [];
  final Map<String, TextEditingController> _controladoresParametros = {};
  bool _carregandoGlobais = true;
  bool _salvandoGlobais = false;

  /* ---- Logs ---- */
  final _filtroTermo = TextEditingController();
  String _filtroInicio = '';
  String _filtroFim = '';
  List<LogAuditoria> _logs = const [];
  bool _carregandoLogs = false;

  String? _erro;

  @override
  void initState() {
    super.initState();
    _buscaUsuario.addListener(() => setState(() {}));
    _carregarTudo();
  }

  @override
  void dispose() {
    _buscaUsuario.dispose();
    _filtroTermo.dispose();
    for (final c in _controladoresParametros.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarTudo() async {
    setState(() {
      _carregandoUsuarios = true;
      _carregandoGlobais = true;
      _erro = null;
    });
    await Future.wait([_carregarUsuarios(), _carregarGlobais()]);
  }

  Future<void> _carregarUsuarios() async {
    try {
      final resultados = await Future.wait([
        _acesso.listarUsuarios(),
        _acesso.listarGrupos(),
        _acesso.listarModulos(),
      ]);
      if (!mounted) return;
      setState(() {
        _usuarios = resultados[0] as List<UsuarioApi>;
        _grupos = resultados[1] as List<GrupoApi>;
        _modulos = resultados[2] as List<ModuloApi>;
        _grupoSelecionadoId ??= _grupos.isEmpty ? null : _grupos.first.id;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregandoUsuarios = false);
    }
  }

  Future<void> _carregarGlobais() async {
    try {
      final resultados = await Future.wait([
        _globais.listarRegras(),
        _globais.listarParametros(),
      ]);
      if (!mounted) return;
      final parametros = resultados[1] as List<ParametroSistema>;
      for (final p in parametros) {
        _controladoresParametros.putIfAbsent(
          p.chave,
          () => TextEditingController(text: p.valor),
        );
      }
      setState(() {
        _regras = resultados[0] as List<RegraAlerta>;
        _parametros = parametros;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregandoGlobais = false);
    }
  }

  Future<void> _carregarLogs() async {
    setState(() => _carregandoLogs = true);
    try {
      final lista = await _auditoria.listar(
        termo: _filtroTermo.text,
        inicio: _filtroInicio,
        fim: _filtroFim,
      );
      if (!mounted) return;
      setState(() => _logs = lista);
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _carregandoLogs = false);
    }
  }

  List<UsuarioApi> get _usuariosFiltrados {
    final termo = _buscaUsuario.text.trim().toLowerCase();
    if (termo.isEmpty) return _usuarios;
    return _usuarios.where((u) {
      final grupo = _nomeGrupo(u.grupoId).toLowerCase();
      return u.nomeCompleto.toLowerCase().contains(termo) ||
          u.cpf.toLowerCase().contains(termo) ||
          u.status.toLowerCase().contains(termo) ||
          grupo.contains(termo);
    }).toList();
  }

  String _nomeGrupo(int grupoId) =>
      _grupos.where((g) => g.id == grupoId).firstOrNull?.nomenclatura ?? 'Indefinido';

  GrupoApi? get _grupoEmEdicao {
    if (_grupos.isEmpty) return null;
    return _grupos.where((g) => g.id == _grupoSelecionadoId).firstOrNull ?? _grupos.first;
  }

  Future<void> _alternarModulo(GrupoApi grupo, String chave) async {
    final modulos = grupo.modulos.contains(chave)
        ? grupo.modulos.where((m) => m != chave).toList()
        : [...grupo.modulos, chave];

    setState(() {
      _grupos = _grupos
          .map((g) => g.id == grupo.id
              ? GrupoApi(
                  id: g.id,
                  nomenclatura: g.nomenclatura,
                  finalidade: g.finalidade,
                  modulos: modulos,
                )
              : g)
          .toList();
    });

    try {
      final resposta = await _acesso.definirModulos(grupo.id, modulos);
      if (!mounted) return;
      setState(() {
        _grupos = _grupos
            .map((g) => g.id == grupo.id
                ? GrupoApi(
                    id: resposta.id,
                    nomenclatura: resposta.nomenclatura,
                    finalidade: resposta.finalidade,
                    modulos: resposta.modulos,
                  )
                : g)
            .toList();
      });
    } catch (e) {
      if (mounted) {
        Toast.erro(context, e.toString());
        await _carregarUsuarios();
      }
    }
  }

  Future<void> _alternarRegra(RegraAlerta regra) async {
    final ativa = !regra.ativa;

    setState(() {
      _regras = _regras
          .map((r) => r.codigo == regra.codigo ? r.copiarCom(ativa: ativa) : r)
          .toList();
    });

    try {
      final salva = await _globais.definirAtiva(regra.codigo, ativa);
      if (!mounted) return;
      setState(() {
        _regras = _regras.map((r) => r.codigo == salva.codigo ? salva : r).toList();
      });
    } catch (e) {
      if (mounted) {
        Toast.erro(context, e.toString());
        await _carregarGlobais();
      }
    }
  }

  Future<void> _gravarParametros() async {
    final alterados = _parametros.where((p) {
      final controlador = _controladoresParametros[p.chave];
      return controlador != null && controlador.text != p.valor;
    }).toList();

    if (alterados.isEmpty) {
      Toast.aviso(context, 'Nenhuma alteração de parâmetro para salvar.');
      return;
    }

    setState(() => _salvandoGlobais = true);
    try {
      for (final p in alterados) {
        await _globais.salvarValor(p.chave, _controladoresParametros[p.chave]!.text);
      }
      if (!mounted) return;
      Toast.sucesso(context, 'Parâmetros atualizados.');
      await _carregarGlobais();
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvandoGlobais = false);
    }
  }

  Future<void> _abrirUsuario({UsuarioApi? usuario}) async {
    if (_grupos.isEmpty) {
      Toast.aviso(context, 'Nenhum grupo de acesso carregado.');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalUsuario(
        acesso: _acesso,
        grupos: _grupos,
        usuario: usuario,
        nomeAutor: widget.auth.sessao?.nomeCompleto ?? 'Administrador',
      ),
    );
    await _carregarUsuarios();
  }

  @override
  Widget build(BuildContext context) {
    return SgsstScaffold(
      titulo: 'Configurações',
      subtitulo: 'Acessos, parâmetros e auditoria',
      child: Column(
        children: [
          Material(
            color: AppCores.petroleo,
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _guias.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final (id, rotulo, icone) = _guias[i];
                  final ativo = id == _guia;
                  return TextButton.icon(
                    onPressed: () {
                      setState(() => _guia = id);
                      if (id == 'logs') _carregarLogs();
                    },
                    icon: Icon(icone, size: 17, color: ativo ? Colors.white : const Color(0xB3FFFFFF)),
                    label: Text(
                      rotulo,
                      style: TextStyle(
                        color: ativo ? Colors.white : const Color(0xB3FFFFFF),
                        fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: _erro != null && _guia != 'logs'
                ? EstadoErro(mensagem: _erro!, aoTentarNovamente: _carregarTudo)
                : _corpo(),
          ),
        ],
      ),
    );
  }

  Widget _corpo() {
    switch (_guia) {
      case 'usuarios':
        return _guiaUsuarios();
      case 'grupos':
        return _guiaGrupos();
      case 'matriz':
        return _guiaMatriz();
      case 'globais':
        return _guiaGlobais();
      case 'logs':
        return _guiaLogs();
    }
    return const SizedBox.shrink();
  }

  Widget _guiaUsuarios() {
    if (_carregandoUsuarios) return const EstadoCarregando(mensagem: 'Carregando usuários...');

    return RefreshIndicator(
      onRefresh: _carregarUsuarios,
      color: AppCores.petroleo,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: _buscaUsuario,
            decoration: InputDecoration(
              hintText: 'Buscar por nome, CPF, status ou grupo',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppCores.hairline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppCores.hairline),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _abrirUsuario(),
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Novo usuário'),
          ),
          const SizedBox(height: 12),
          if (_usuariosFiltrados.isEmpty)
            const EstadoVazio(mensagem: 'Nenhum usuário encontrado.', icone: Icons.people_outline)
          else
            for (final u in _usuariosFiltrados) ...[
              CartaoSgsst(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              u.nomeCompleto,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppCores.tinta,
                              ),
                            ),
                          ),
                          Etiqueta(
                            texto: u.status,
                            cor: u.status == 'Ativo' ? AppCores.valido : AppCores.cinza,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinhaDetalhe(rotulo: 'Login', valor: u.login),
                      LinhaDetalhe(rotulo: 'E-mail', valor: u.email),
                      LinhaDetalhe(rotulo: 'CPF', valor: u.cpf),
                      LinhaDetalhe(rotulo: 'Grupo', valor: u.grupo),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          BotaoTexto(
                            rotulo: 'Editar',
                            icone: Icons.edit_outlined,
                            aoClicar: () => _abrirUsuario(usuario: u),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _guiaGrupos() {
    if (_carregandoUsuarios) return const EstadoCarregando();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        for (final g in _grupos) ...[
          CartaoSecao(
            titulo: g.nomenclatura,
            subtitulo: g.finalidade,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Módulos liberados: ${g.modulos.isEmpty ? 'nenhum' : g.modulos.length}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: BotaoTexto(
                    rotulo: 'Editar matriz',
                    icone: Icons.grid_view_outlined,
                    aoClicar: () {
                      setState(() {
                        _grupoSelecionadoId = g.id;
                        _guia = 'matriz';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _guiaMatriz() {
    final grupo = _grupoEmEdicao;
    if (_carregandoUsuarios) return const EstadoCarregando();
    if (grupo == null) {
      return const EstadoVazio(mensagem: 'Nenhum grupo de acesso cadastrado.');
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        CampoSelecao<int>(
          rotulo: 'Grupo de acesso',
          valor: grupo.id,
          opcoes: [
            for (final g in _grupos)
              DropdownMenuItem(value: g.id, child: Text(g.nomenclatura)),
          ],
          aoMudar: (id) => setState(() => _grupoSelecionadoId = id),
        ),
        const SizedBox(height: 12),
        CartaoSecao(
          titulo: 'Matriz de acessos',
          subtitulo: 'Marque os módulos liberados para ${grupo.nomenclatura}',
          child: _modulos.isEmpty
              ? const EstadoVazio(mensagem: 'Nenhum módulo retornado pela API.')
              : Column(
                  children: [
                    for (final m in _modulos)
                      SwitchListTile(
                        value: grupo.modulos.contains(m.chave),
                        onChanged: (_) => _alternarModulo(grupo, m.chave),
                        title: Text(m.titulo,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(m.detalhe),
                        activeThumbColor: AppCores.petroleo,
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _guiaGlobais() {
    if (_carregandoGlobais) {
      return const EstadoCarregando(mensagem: 'Carregando configurações...');
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        CartaoSecao(
          titulo: 'Regras de alerta',
          subtitulo: 'Ative ou desative cada regra monitorada',
          child: _regras.isEmpty
              ? const EstadoVazio(mensagem: 'Nenhuma regra de alerta cadastrada.')
              : Column(
                  children: [
                    for (final r in _regras)
                      SwitchListTile(
                        value: r.ativa,
                        onChanged: (_) => _alternarRegra(r),
                        title: Text(r.nomeRegra,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(r.descricaoRegra),
                        activeThumbColor: AppCores.petroleo,
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        CartaoSecao(
          titulo: 'Parâmetros do sistema',
          subtitulo: 'Só o que mudou é gravado',
          child: _parametros.isEmpty
              ? const EstadoVazio(mensagem: 'Nenhum parâmetro cadastrado.')
              : Column(
                  children: [
                    for (final p in _parametros) ...[
                      if (_controladoresParametros[p.chave] != null)
                        CampoTexto(
                          rotulo: p.descricao.isEmpty ? p.chave : p.descricao,
                          controlador: _controladoresParametros[p.chave]!,
                        ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 6),
                    BotaoPrimario(
                      rotulo: 'Salvar Configurações',
                      carregando: _salvandoGlobais,
                      aoClicar: _gravarParametros,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _guiaLogs() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        CartaoSecao(
          titulo: 'Filtros',
          child: Column(
            children: [
              CampoTexto(
                rotulo: 'Termo',
                controlador: _filtroTermo,
                aoSubmeter: (_) => _carregarLogs(),
              ),
              const SizedBox(height: 12),
              CampoData(
                rotulo: 'Início',
                valor: _filtroInicio,
                aoEscolher: (v) => setState(() => _filtroInicio = v),
              ),
              const SizedBox(height: 12),
              CampoData(
                rotulo: 'Fim',
                valor: _filtroFim,
                aoEscolher: (v) => setState(() => _filtroFim = v),
              ),
              const SizedBox(height: 14),
              BotaoPrimario(
                rotulo: 'Buscar logs',
                icone: Icons.search,
                carregando: _carregandoLogs,
                aoClicar: _carregarLogs,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CartaoSecao(
          titulo: 'Logs de auditoria',
          subtitulo: '${_logs.length} registro(s)',
          child: _logs.isEmpty
              ? const EstadoVazio(mensagem: 'Nenhum log encontrado.', icone: Icons.history)
              : Column(
                  children: [
                    for (final log in _logs) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              log.descricao,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppCores.tinta,
                              ),
                            ),
                          ),
                          Etiqueta(texto: log.acao, cor: AppCores.petroleo),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinhaDetalhe(rotulo: 'Data/hora', valor: Formato.dataHora(log.dataHora)),
                      LinhaDetalhe(rotulo: 'Usuário', valor: log.usuario),
                      LinhaDetalhe(rotulo: 'Módulo', valor: log.modulo),
                      if (log != _logs.last) const Divider(height: 18),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ModalUsuario extends StatefulWidget {
  const _ModalUsuario({
    required this.acesso,
    required this.grupos,
    required this.usuario,
    required this.nomeAutor,
  });

  final AcessoService acesso;
  final List<GrupoApi> grupos;
  final UsuarioApi? usuario;
  final String nomeAutor;

  @override
  State<_ModalUsuario> createState() => _ModalUsuarioState();
}

class _ModalUsuarioState extends State<_ModalUsuario> {
  late final TextEditingController _nomeCompleto =
      TextEditingController(text: widget.usuario?.nomeCompleto ?? '');
  late final TextEditingController _login =
      TextEditingController(text: widget.usuario?.login ?? '');
  late final TextEditingController _email =
      TextEditingController(text: widget.usuario?.email ?? '');
  late final TextEditingController _cpf =
      TextEditingController(text: widget.usuario?.cpf ?? '');
  late final TextEditingController _senha = TextEditingController();
  late int? _grupoId = widget.usuario?.grupoId ??
      (widget.grupos.isEmpty ? null : widget.grupos.first.id);
  late String _status = widget.usuario?.status ?? 'Ativo';
  bool _salvando = false;

  bool get _novo => widget.usuario == null;

  @override
  void dispose() {
    for (final c in [_nomeCompleto, _login, _email, _cpf, _senha]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando) return;

    final senha = _senha.text.trim();

    if (_nomeCompleto.text.trim().isEmpty || _login.text.trim().isEmpty) {
      Toast.erro(context, 'Informe o nome completo e o usuário de acesso.');
      return;
    }
    if (_cpf.text.replaceAll(RegExp(r'\D'), '').length != 11) {
      Toast.erro(context, 'O CPF deve conter 11 dígitos.');
      return;
    }
    if (_novo && (senha.length < 6 || senha.length > 72)) {
      Toast.erro(context, 'Informe uma senha de 6 a 72 caracteres.');
      return;
    }
    if (!_novo && senha.isNotEmpty && (senha.length < 6 || senha.length > 72)) {
      Toast.erro(context, 'A nova senha deve ter de 6 a 72 caracteres.');
      return;
    }
    if (_grupoId == null) {
      Toast.erro(context, 'Selecione o grupo de acesso.');
      return;
    }

    final dados = {
      'nomeCompleto': _nomeCompleto.text.trim(),
      'login': _login.text.trim(),
      'email': _email.text.trim(),
      'cpf': _cpf.text,
      'grupoId': _grupoId,
      'status': _status,
      if (senha.isNotEmpty) 'senha': senha,
    };

    setState(() => _salvando = true);
    try {
      if (_novo) {
        await widget.acesso.criarUsuario(dados);
      } else {
        await widget.acesso.atualizarUsuario(widget.usuario!.id, dados);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      Toast.sucesso(
        context,
        _novo ? 'Usuário cadastrado com sucesso!' : 'Usuário atualizado com sucesso!',
      );
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.96,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppCores.areia,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: AppCores.hairline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _novo ? 'Novo usuário' : 'Editar usuário',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            CampoTexto(rotulo: 'Nome completo', controlador: _nomeCompleto, maxCaracteres: 150),
            const SizedBox(height: 12),
            CampoTexto(rotulo: 'Usuário de acesso', controlador: _login, maxCaracteres: 60),
            const SizedBox(height: 12),
            CampoTexto(rotulo: 'E-mail', controlador: _email, maxCaracteres: 180),
            const SizedBox(height: 12),
            CampoTexto(
              rotulo: 'CPF',
              controlador: _cpf,
              maxCaracteres: 14,
              tipoTeclado: TextInputType.number,
            ),
            const SizedBox(height: 12),
            CampoSelecao<int>(
              rotulo: 'Grupo de acesso',
              valor: _grupoId,
              opcoes: [
                for (final g in widget.grupos)
                  DropdownMenuItem(value: g.id, child: Text(g.nomenclatura)),
              ],
              aoMudar: (v) => setState(() => _grupoId = v),
            ),
            const SizedBox(height: 12),
            CampoSelecao<String>(
              rotulo: 'Status',
              valor: _status,
              opcoes: const [
                DropdownMenuItem(value: 'Ativo', child: Text('Ativo')),
                DropdownMenuItem(value: 'Inativo', child: Text('Inativo')),
              ],
              aoMudar: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 12),
            CampoTexto(
              rotulo: _novo ? 'Senha (6 a 72 caracteres)' : 'Nova senha (opcional)',
              controlador: _senha,
              obscuro: true,
            ),
            const SizedBox(height: 20),
            BotaoPrimario(
              rotulo: 'Salvar',
              carregando: _salvando,
              aoClicar: _salvar,
            ),
            TextButton(
              onPressed: _salvando ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
