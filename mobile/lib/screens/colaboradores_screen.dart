import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/toast.dart';
import '../core/validacao.dart';
import '../models/colaborador.dart';
import '../services/auth_service.dart';
import '../services/colaborador_service.dart';
import '../services/dados_referencia.dart';
import '../widgets/campo_formulario.dart';
import '../widgets/cartao_secao.dart';
import '../widgets/estado_tela.dart';
import '../widgets/sgsst_scaffold.dart';
import 'cadastramentos_screen.dart';

/// Porta de `src/app/tela-colaboradores`.
class ColaboradoresScreen extends StatefulWidget {
  const ColaboradoresScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<ColaboradoresScreen> createState() => _ColaboradoresScreenState();
}

class _ColaboradoresScreenState extends State<ColaboradoresScreen> {
  late final ColaboradorService _api = ColaboradorService(widget.auth);

  final _busca = TextEditingController();
  List<Colaborador> _colaboradores = const [];
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _busca.addListener(() => setState(() {}));
    _carregar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final itens = await _api.listar();
      if (!mounted) return;
      setState(() => _colaboradores = itens);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<Colaborador> get _filtrados {
    final termo = _busca.text.trim().toLowerCase();
    if (termo.isEmpty) return _colaboradores;
    return _colaboradores.where((c) {
      return [c.nome, c.matricula, c.cpf, c.email, c.cargo, c.setor, c.status]
          .any((v) => v.toLowerCase().contains(termo));
    }).toList();
  }

  /// Novo cadastro vai para a aba "Colaborador" da tela de Cadastramentos.
  Future<void> _novoColaborador() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CadastramentosScreen(auth: widget.auth, abaInicial: 'colaborador'),
      ),
    );
    await _carregar();
  }

  Future<void> _abrirDetalhes(Colaborador colaborador) async {
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      final item = await _api.buscarPorId(colaborador.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DetalhesColaborador(
          api: _api,
          original: item,
          aoAtualizar: (atualizado) {
            if (!mounted) return;
            setState(() {
              _colaboradores = _colaboradores
                  .map((c) => c.id == atualizado.id ? atualizado : c)
                  .toList();
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

  Future<void> _excluir(Colaborador item) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir colaborador'),
        content: Text('Excluir "${item.nome}"? Esta ação não pode ser desfeita.'),
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
      await _api.excluir(item.id);
      if (!mounted) return;
      setState(() => _colaboradores = _colaboradores.where((c) => c.id != item.id).toList());
      Toast.sucesso(context, 'Registro excluído com sucesso!');
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SgsstScaffold(
      embutido: true,
      titulo: 'Colaboradores',
      subtitulo: 'Equipe e Matriz de SST',
      acao: IconButton(
        tooltip: 'Cadastrar novo colaborador',
        icon: const Icon(Icons.person_add_alt),
        onPressed: _novoColaborador,
      ),
      child: RefreshIndicator(
        onRefresh: _carregar,
        color: AppCores.petroleo,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            TextField(
              controller: _busca,
              decoration: InputDecoration(
                hintText: 'Buscar por nome, CPF, matrícula, cargo ou setor',
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
            if (_carregando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: EstadoCarregando(mensagem: 'Carregando colaboradores...'),
              )
            else if (_erro != null)
              EstadoErro(mensagem: _erro!, aoTentarNovamente: _carregar)
            else if (_filtrados.isEmpty)
              EstadoVazio(mensagem: 'Nenhum colaborador encontrado.', icone: Icons.people_outline)
            else ...[
              Text(
                '${_filtrados.length} de ${_colaboradores.length} registros',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              for (final c in _filtrados) ...[
                _CartaoColaborador(
                  colaborador: c,
                  aoVerDetalhes: () => _abrirDetalhes(c),
                  aoExcluir: () => _excluir(c),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CartaoColaborador extends StatelessWidget {
  const _CartaoColaborador({
    required this.colaborador,
    required this.aoVerDetalhes,
    required this.aoExcluir,
  });

  final Colaborador colaborador;
  final VoidCallback aoVerDetalhes;
  final VoidCallback aoExcluir;

  @override
  Widget build(BuildContext context) {
    return CartaoSgsst(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    colaborador.nome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppCores.tinta,
                    ),
                  ),
                ),
                Etiqueta.colaborador(colaborador.status),
              ],
            ),
            const SizedBox(height: 8),
            LinhaDetalhe(rotulo: 'CPF / Matrícula', valor: '${colaborador.cpf} · ${colaborador.matricula}'),
            LinhaDetalhe(rotulo: 'Cargo / Setor', valor: '${colaborador.cargo} · ${colaborador.setor}'),
            LinhaDetalhe(rotulo: 'E-mail', valor: colaborador.email),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                BotaoTexto(
                  rotulo: 'Ver Detalhes / Editar',
                  icone: Icons.edit_outlined,
                  aoClicar: aoVerDetalhes,
                ),
                BotaoTexto(
                  rotulo: 'Excluir',
                  icone: Icons.delete_outline,
                  cor: AppCores.vencido,
                  aoClicar: aoExcluir,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal de detalhes/edição do colaborador (equivalente ao modal do web).
class _DetalhesColaborador extends StatefulWidget {
  const _DetalhesColaborador({
    required this.api,
    required this.original,
    required this.aoAtualizar,
  });

  final ColaboradorService api;
  final Colaborador original;
  final ValueChanged<Colaborador> aoAtualizar;

  @override
  State<_DetalhesColaborador> createState() => _DetalhesColaboradorState();
}

class _DetalhesColaboradorState extends State<_DetalhesColaborador> {
  late final TextEditingController _nome = TextEditingController(text: widget.original.nome);
  late final TextEditingController _email = TextEditingController(text: widget.original.email);
  late final TextEditingController _matricula =
      TextEditingController(text: widget.original.matricula);
  late final TextEditingController _cpf = TextEditingController(text: widget.original.cpf);
  late final TextEditingController _cargo = TextEditingController(text: widget.original.cargo);
  late final TextEditingController _setor = TextEditingController(text: widget.original.setor);
  late String _status = widget.original.status;

  bool _salvando = false;
  final _formulario = GlobalKey<FormState>();

  @override
  void dispose() {
    for (final c in [_nome, _email, _matricula, _cpf, _cargo, _setor]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando || !(_formulario.currentState?.validate() ?? false)) return;

    final dados = {
      'matricula': _matricula.text.trim(),
      'nome': _nome.text.trim(),
      'cpf': _cpf.text.trim(),
      'email': _email.text.trim(),
      'cargo': _cargo.text.trim(),
      'setor': _setor.text.trim(),
      'status': _status,
    };

    if (!Validacao.colaborador(
      matricula: dados['matricula']!,
      nome: dados['nome']!,
      cpf: dados['cpf']!,
      email: dados['email']!,
      cargo: dados['cargo']!,
      setor: dados['setor']!,
      status: _status,
    )) {
      Toast.erro(context, 'Informe os campos obrigatórios, CPF e e-mail válidos.');
      return;
    }

    setState(() => _salvando = true);
    try {
      final atualizado = await widget.api.atualizar(widget.original.id, dados);
      if (!mounted) return;
      widget.aoAtualizar(atualizado);
      Navigator.of(context).pop();
      Toast.sucesso(context, 'Colaborador atualizado com sucesso!');
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.96,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppCores.areia,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formulario,
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
              Text(widget.original.nome, style: Theme.of(context).textTheme.titleLarge),
              Text('Detalhes e edição', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              CampoTexto(rotulo: 'Nome Completo', controlador: _nome, maxCaracteres: 150),
              const SizedBox(height: 12),
              CampoTexto(rotulo: 'E-mail', controlador: _email, maxCaracteres: 180),
              const SizedBox(height: 12),
              CampoTexto(rotulo: 'Matrícula', controlador: _matricula, maxCaracteres: 30),
              const SizedBox(height: 12),
              CampoTexto(
                rotulo: 'CPF',
                controlador: _cpf,
                maxCaracteres: 14,
                tipoTeclado: TextInputType.number,
              ),
              const SizedBox(height: 12),
              CampoSelecao<String>(
                rotulo: 'Status',
                valor: _status,
                opcoes: const [
                  DropdownMenuItem(value: 'Ativo', child: Text('Ativo')),
                  DropdownMenuItem(value: 'Inativo', child: Text('Inativo')),
                  DropdownMenuItem(value: 'Afastado', child: Text('Afastado')),
                ],
                aoMudar: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 12),
              CampoTexto(rotulo: 'Cargo', controlador: _cargo, maxCaracteres: 120),
              const SizedBox(height: 12),
              CampoTexto(rotulo: 'Setor', controlador: _setor, maxCaracteres: 120),
              const SizedBox(height: 20),
              // O web mostra estes blocos sempre vazios ("fora do escopo").
              CartaoSecao(
                titulo: 'EPIs Vinculados',
                child: Text(
                  'Entregas e vínculos de EPIs fora do escopo.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 10),
              CartaoSecao(
                titulo: 'Treinamentos e Certificações',
                child: Text(
                  'Vínculos e certificações fora do escopo.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 10),
              CartaoSecao(
                titulo: 'Reciclagens',
                child: Text(
                  'Reciclagens fora do escopo.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 20),
              BotaoPrimario(
                rotulo: 'Salvar Alterações',
                carregando: _salvando,
                aoClicar: _salvar,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _salvando ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mantido para o rótulo dos registros (o web exibe "Colaborador Essenza").
const rotuloEmpresa = 'Colaborador Essenza';

// Referência às listas fixas usadas nos cadastros (mesma fonte do web).
// ignore: unused_element
final _cargos = DadosReferencia.cargosCadastrados;
