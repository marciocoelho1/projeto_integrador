import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatadores.dart';
import '../core/toast.dart';
import '../core/validacao.dart';
import '../models/colaborador.dart';
import '../models/epi.dart';
import '../services/auth_service.dart';
import '../services/colaborador_service.dart';
import '../services/epi_service.dart';
import '../widgets/campo_formulario.dart';
import '../widgets/cartao_secao.dart';
import '../widgets/estado_tela.dart';
import '../widgets/sgsst_scaffold.dart';
import 'cadastramentos_screen.dart';

/// Porta de `src/app/tela-epis`: estoque, edição de EPI e registro de entregas
/// (a entrega abate o estoque no servidor; excluir estorna).
class EpisScreen extends StatefulWidget {
  const EpisScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<EpisScreen> createState() => _EpisScreenState();
}

class _EpisScreenState extends State<EpisScreen> {
  late final EpiService _api = EpiService(widget.auth);
  late final ColaboradorService _apiColaboradores = ColaboradorService(widget.auth);

  final _busca = TextEditingController();
  List<Epi> _epis = const [];
  List<EntregaEpi> _entregas = const [];
  List<Colaborador> _colaboradores = const [];

  bool _carregando = true;
  bool _carregandoEntregas = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _busca.addListener(() => setState(() {}));
    _atualizarListas();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _atualizarListas() async {
    setState(() {
      _carregando = true;
      _carregandoEntregas = true;
      _erro = null;
    });
    try {
      final epis = await _api.obterEpis();
      final entregas = await _api.obterEntregas();
      if (!mounted) return;
      setState(() {
        _epis = epis;
        _entregas = entregas;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
          _carregandoEntregas = false;
        });
      }
    }
  }

  List<Epi> get _episFiltrados {
    final termo = _busca.text.trim().toLowerCase();
    if (termo.isEmpty) return _epis;
    return _epis
        .where((e) =>
            e.descricao.toLowerCase().contains(termo) ||
            e.id.toString().contains(termo) ||
            e.ca.toLowerCase().contains(termo))
        .toList();
  }

  Future<void> _novoEpi() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CadastramentosScreen(auth: widget.auth, abaInicial: 'epi'),
      ),
    );
    await _atualizarListas();
  }

  Future<void> _abrirEdicao(Epi epi) async {
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      final item = await _api.obterEpiPorId(epi.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _EditarEpi(
          api: _api,
          original: item,
          aoAtualizar: (atualizado) {
            if (!mounted) return;
            setState(() {
              _epis = _epis.map((e) => e.id == atualizado.id ? atualizado : e).toList();
            });
          },
        ),
      );
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _excluir(Epi item) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir EPI'),
        content: Text('Excluir "${item.descricao}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppCores.vencido),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _salvando = true);
    try {
      await _api.excluirEpi(item.id);
      if (!mounted) return;
      setState(() => _epis = _epis.where((e) => e.id != item.id).toList());
      Toast.sucesso(context, 'Registro excluído com sucesso!');
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _abrirEntrega() async {
    setState(() {
      _carregando = true;
    });
    try {
      final colaboradores = await _apiColaboradores.listar();
      if (!mounted) return;
      _colaboradores = colaboradores;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _RegistrarEntrega(
          api: _api,
          epis: _epis,
          colaboradores: _colaboradores,
        ),
      );
      await _atualizarListas();
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _excluirEntrega(EntregaEpi entrega) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir entrega'),
        content: Text(
          'Excluir a entrega de "${entrega.epi}"? O estoque será estornado.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppCores.vencido),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _salvando = true);
    try {
      await _api.excluirEntrega(entrega.id);
      if (!mounted) return;
      Toast.sucesso(context, 'Entrega excluída e estoque estornado!');
      await _atualizarListas();
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SgsstScaffold(
      titulo: 'EPIs',
      subtitulo: 'Estoque e entregas',
      acoes: [
        IconButton(
          tooltip: 'Registrar entrega',
          icon: const Icon(Icons.assignment_turned_in_outlined),
          onPressed: _abrirEntrega,
        ),
        IconButton(
          tooltip: 'Cadastrar EPI',
          icon: const Icon(Icons.add_box_outlined),
          onPressed: _novoEpi,
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _atualizarListas,
        color: AppCores.petroleo,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              'Registre a entrega para abater o estoque do EPI; exclua uma entrega para '
              'estornar a quantidade.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _busca,
              decoration: InputDecoration(
                hintText: 'Buscar EPIs por nome, ID ou CA...',
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
            const SizedBox(height: 14),
            if (_erro != null)
              EstadoErro(mensagem: _erro!, aoTentarNovamente: _atualizarListas)
            else if (_carregando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: EstadoCarregando(mensagem: 'Carregando estoque...'),
              )
            else ...[
              CartaoSecao(
                titulo: 'Controle de Estoque de EPIs',
                subtitulo: '${_episFiltrados.length} de ${_epis.length} itens',
                child: _episFiltrados.isEmpty
                    ? const EstadoVazio(mensagem: 'Nenhum EPI encontrado.', icone: Icons.shield_outlined)
                    : Column(
                        children: [
                          for (final epi in _episFiltrados) ...[
                            _LinhaEpi(
                              epi: epi,
                              aoEditar: () => _abrirEdicao(epi),
                              aoExcluir: () => _excluir(epi),
                            ),
                            if (epi != _episFiltrados.last) const Divider(height: 18),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              CartaoSecao(
                titulo: 'Entregas Registradas',
                subtitulo: '${_entregas.length} registro(s)',
                child: _carregandoEntregas
                    ? const EstadoCarregando()
                    : _entregas.isEmpty
                        ? const EstadoVazio(
                            mensagem:
                                'Nenhuma entrega registrada. Registre uma entrega ou atualize a lista.',
                            icone: Icons.assignment_outlined,
                          )
                        : Column(
                            children: [
                              for (final e in _entregas) ...[
                                _LinhaEntrega(
                                  entrega: e,
                                  aoExcluir: () => _excluirEntrega(e),
                                ),
                                if (e != _entregas.last) const Divider(height: 18),
                              ],
                            ],
                          ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinhaEpi extends StatelessWidget {
  const _LinhaEpi({required this.epi, required this.aoEditar, required this.aoExcluir});

  final Epi epi;
  final VoidCallback aoEditar;
  final VoidCallback aoExcluir;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                epi.descricao,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppCores.tinta,
                ),
              ),
            ),
            Text(
              '${epi.quantidade} un',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: epi.estoqueCritico ? AppCores.vencido : AppCores.valido,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinhaDetalhe(rotulo: 'ID / CA', valor: '#${epi.id} · CA ${Formato.texto(epi.ca)}'),
        LinhaDetalhe(rotulo: 'Inclusão', valor: Formato.data(epi.inclusao)),
        LinhaDetalhe(rotulo: 'Validade', valor: Formato.data(epi.validade)),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            BotaoTexto(rotulo: 'Editar', icone: Icons.edit_outlined, aoClicar: aoEditar),
            BotaoTexto(
              rotulo: 'Excluir',
              icone: Icons.delete_outline,
              cor: AppCores.vencido,
              aoClicar: aoExcluir,
            ),
          ],
        ),
      ],
    );
  }
}

class _LinhaEntrega extends StatelessWidget {
  const _LinhaEntrega({required this.entrega, required this.aoExcluir});

  final EntregaEpi entrega;
  final VoidCallback aoExcluir;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entrega.colaborador,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppCores.tinta),
              ),
            ),
            Text('${entrega.quantidade} un', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        LinhaDetalhe(rotulo: 'EPI', valor: entrega.epi),
        LinhaDetalhe(rotulo: 'CA', valor: Formato.texto(entrega.ca)),
        LinhaDetalhe(rotulo: 'Data', valor: Formato.data(entrega.dataEntrega)),
        LinhaDetalhe(rotulo: 'Assinatura', valor: entrega.assinatura),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            BotaoTexto(
              rotulo: 'Excluir entrega',
              icone: Icons.undo,
              cor: AppCores.vencido,
              aoClicar: aoExcluir,
            ),
          ],
        ),
      ],
    );
  }
}

class _EditarEpi extends StatefulWidget {
  const _EditarEpi({required this.api, required this.original, required this.aoAtualizar});

  final EpiService api;
  final Epi original;
  final ValueChanged<Epi> aoAtualizar;

  @override
  State<_EditarEpi> createState() => _EditarEpiState();
}

class _EditarEpiState extends State<_EditarEpi> {
  late final TextEditingController _descricao = TextEditingController(text: widget.original.descricao);
  late final TextEditingController _quantidade =
      TextEditingController(text: '${widget.original.quantidade}');
  late final TextEditingController _ca = TextEditingController(text: widget.original.ca);
  late String _validade = widget.original.validade;
  late String _inclusao = widget.original.inclusao;
  bool _salvando = false;

  @override
  void dispose() {
    _descricao.dispose();
    _quantidade.dispose();
    _ca.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando) return;

    final quantidade = int.tryParse(_quantidade.text.trim()) ?? -1;

    if (!Validacao.epi(
      descricao: _descricao.text.trim(),
      ca: _ca.text.trim(),
      quantidade: quantidade,
      inclusao: _inclusao,
      validade: _validade,
    )) {
      Toast.erro(context, 'Preencha os campos e uma quantidade inteira não negativa.');
      return;
    }

    setState(() => _salvando = true);
    try {
      final atualizado = await widget.api.atualizarEpi(widget.original.id, {
        'descricao': _descricao.text.trim(),
        'quantidade': quantidade,
        'ca': _ca.text.trim(),
        'validade': _validade,
        'inclusao': _inclusao,
      });
      if (!mounted) return;
      widget.aoAtualizar(atualizado);
      Navigator.of(context).pop();
      Toast.sucesso(context, 'EPI atualizado com sucesso!');
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
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
            Text('Editar EPI #${widget.original.id}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            CampoTexto(rotulo: 'Descrição', controlador: _descricao, maxCaracteres: 180),
            const SizedBox(height: 12),
            CampoTexto(
              rotulo: 'Quantidade em estoque',
              controlador: _quantidade,
              tipoTeclado: TextInputType.number,
            ),
            const SizedBox(height: 12),
            CampoTexto(
              rotulo: 'Número do CA',
              controlador: _ca,
              maxCaracteres: 30,
              tipoTeclado: TextInputType.number,
            ),
            const SizedBox(height: 12),
            CampoData(
              rotulo: 'Validade (CA)',
              valor: _validade,
              aoEscolher: (v) => setState(() => _validade = v),
            ),
            const SizedBox(height: 12),
            CampoData(
              rotulo: 'Data de inclusão',
              valor: _inclusao,
              ultima: Formato.paraData(_validade) ?? DateTime(2100),
              aoEscolher: (v) => setState(() => _inclusao = v),
            ),
            const SizedBox(height: 20),
            BotaoPrimario(
              rotulo: 'Salvar Alterações',
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

class _RegistrarEntrega extends StatefulWidget {
  const _RegistrarEntrega({
    required this.api,
    required this.epis,
    required this.colaboradores,
  });

  final EpiService api;
  final List<Epi> epis;
  final List<Colaborador> colaboradores;

  @override
  State<_RegistrarEntrega> createState() => _RegistrarEntregaState();
}

class _RegistrarEntregaState extends State<_RegistrarEntrega> {
  Colaborador? _colaborador;
  Epi? _epi;
  final _quantidade = TextEditingController(text: '1');
  late String _data = Formato.iso(DateTime.now());
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _quantidade.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando) return;

    final quantidade = int.tryParse(_quantidade.text.trim()) ?? 0;

    if (_colaborador == null || _epi == null || quantidade <= 0 || _data.isEmpty) {
      setState(() => _erro =
          'Selecione um colaborador cadastrado, o EPI, uma quantidade inteira maior que zero e a data.');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await widget.api.registrarEntrega({
        'colaboradorId': _colaborador!.id,
        'epiId': _epi!.id,
        'quantidade': quantidade,
        'dataEntrega': _data,
        'assinatura': _colaborador!.nome,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      Toast.sucesso(context, 'Entrega registrada e estoque atualizado!');
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
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
            Text('Registrar Entrega de EPI',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            CampoSelecao<int>(
              rotulo: 'Colaborador',
              valor: _colaborador?.id,
              opcoes: [
                for (final c in widget.colaboradores)
                  DropdownMenuItem(value: c.id, child: Text(c.nome, overflow: TextOverflow.ellipsis)),
              ],
              aoMudar: (id) => setState(() {
                _colaborador = widget.colaboradores.firstWhere((c) => c.id == id);
              }),
            ),
            const SizedBox(height: 12),
            CampoSelecao<int>(
              rotulo: 'Equipamento (EPI)',
              valor: _epi?.id,
              opcoes: [
                for (final e in widget.epis)
                  DropdownMenuItem(
                    value: e.id,
                    enabled: e.quantidade > 0,
                    child: Text(
                      '${e.descricao} (Estoque: ${e.quantidade})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              aoMudar: (id) => setState(() {
                _epi = widget.epis.firstWhere((e) => e.id == id);
              }),
            ),
            const SizedBox(height: 12),
            CampoTexto(
              rotulo: 'Quantidade entregue',
              controlador: _quantidade,
              tipoTeclado: TextInputType.number,
            ),
            const SizedBox(height: 12),
            CampoData(
              rotulo: 'Data da entrega',
              valor: _data,
              aoEscolher: (v) => setState(() => _data = v),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(_erro!, style: const TextStyle(color: AppCores.vencido)),
            ],
            const SizedBox(height: 20),
            BotaoPrimario(
              rotulo: 'Confirmar Entrega',
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
