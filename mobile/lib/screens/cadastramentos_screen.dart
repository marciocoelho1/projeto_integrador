import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatadores.dart';
import '../core/toast.dart';
import '../core/validacao.dart';
import '../services/auth_service.dart';
import '../services/colaborador_service.dart';
import '../services/dados_referencia.dart';
import '../services/epi_service.dart';
import '../services/treinamento_service.dart';
import '../widgets/campo_formulario.dart';
import '../widgets/cartao_secao.dart';
import '../widgets/sgsst_scaffold.dart';

/// Porta de `src/app/tela-cadastramentos`: aba de cadastro rápido de
/// colaborador, treinamento e EPI. As abas LNT e Reciclagem são apenas avisos
/// "fora do escopo", como no web.
class CadastramentosScreen extends StatefulWidget {
  const CadastramentosScreen({super.key, required this.auth, this.abaInicial = 'colaborador'});

  final AuthService auth;
  final String abaInicial;

  @override
  State<CadastramentosScreen> createState() => _CadastramentosScreenState();
}

class _CadastramentosScreenState extends State<CadastramentosScreen>
    with SingleTickerProviderStateMixin {
  static const _abas = ['colaborador', 'treinamento', 'epi', 'lnt', 'reciclagem'];
  static const _rotulos = ['Colaborador', 'Treinamento', 'EPI', 'LNT', 'Reciclagem'];

  late final TabController _controller = TabController(
    length: _abas.length,
    vsync: this,
    initialIndex: _abas.indexOf(widget.abaInicial).clamp(0, _abas.length - 1),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SgsstScaffold(
      embutido: true,
      titulo: 'Cadastramentos',
      subtitulo: 'Novo registro',
      child: Column(
        children: [
          Material(
            color: AppCores.petroleo,
            child: TabBar(
              controller: _controller,
              isScrollable: true,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xB3FFFFFF),
              tabs: [for (final r in _rotulos) Tab(text: r)],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _controller,
              children: [
                _FormularioColaborador(auth: widget.auth),
                _FormularioTreinamento(auth: widget.auth),
                _FormularioEpi(auth: widget.auth),
                const _ForaDoEscopo(
                  titulo: 'LNT / Cargos',
                  mensagem: 'LNT / Cargos: funcionalidade fora do escopo, sem persistência.',
                ),
                const _ForaDoEscopo(
                  titulo: 'Reciclagens',
                  mensagem: 'Reciclagens: funcionalidade fora do escopo, sem persistência.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ForaDoEscopo extends StatelessWidget {
  const _ForaDoEscopo({required this.titulo, required this.mensagem});

  final String titulo;
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: CartaoSecao(
          titulo: titulo,
          child: Text(mensagem, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    );
  }
}

class _FormularioColaborador extends StatefulWidget {
  const _FormularioColaborador({required this.auth});

  final AuthService auth;

  @override
  State<_FormularioColaborador> createState() => _FormularioColaboradorState();
}

class _FormularioColaboradorState extends State<_FormularioColaborador> {
  late final ColaboradorService _api = ColaboradorService(widget.auth);
  final _matricula = TextEditingController();
  final _nome = TextEditingController();
  final _cpf = TextEditingController();
  final _email = TextEditingController();
  final _cargo = TextEditingController();
  final _setor = TextEditingController();
  String _status = 'Ativo';
  bool _salvando = false;

  Future<void> _salvar() async {
    if (_salvando) return;

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
      Toast.erro(context, 'Confira os campos, tamanhos máximos, CPF com 11 dígitos e e-mail válido.');
      return;
    }

    setState(() => _salvando = true);
    try {
      await _api.criar(dados);
      if (!mounted) return;
      for (final c in [_matricula, _nome, _cpf, _email, _cargo, _setor]) {
        c.clear();
      }
      setState(() => _status = 'Ativo');
      Toast.sucesso(context, 'Colaborador cadastrado com sucesso!');
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        CartaoSecao(
          titulo: 'Novo Colaborador',
          subtitulo: 'Todos os campos são obrigatórios',
          child: Column(
            children: [
              CampoTexto(rotulo: 'Matrícula', controlador: _matricula, maxCaracteres: 30),
              const SizedBox(height: 12),
              CampoTexto(rotulo: 'Nome completo', controlador: _nome, maxCaracteres: 150),
              const SizedBox(height: 12),
              CampoTexto(
                rotulo: 'CPF',
                controlador: _cpf,
                maxCaracteres: 14,
                tipoTeclado: TextInputType.number,
                dica: 'Somente números',
              ),
              const SizedBox(height: 12),
              CampoTexto(
                rotulo: 'E-mail',
                controlador: _email,
                maxCaracteres: 180,
                tipoTeclado: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              CampoTexto(rotulo: 'Cargo', controlador: _cargo, maxCaracteres: 120),
              const SizedBox(height: 6),
              _Sugestoes(
                opcoes: DadosReferencia.cargosCadastrados,
                aoEscolher: (v) => setState(() => _cargo.text = v),
              ),
              const SizedBox(height: 12),
              CampoTexto(rotulo: 'Setor', controlador: _setor, maxCaracteres: 120),
              const SizedBox(height: 6),
              _Sugestoes(
                opcoes: DadosReferencia.setoresCadastrados,
                aoEscolher: (v) => setState(() => _setor.text = v),
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
              const SizedBox(height: 18),
              BotaoPrimario(
                rotulo: 'Cadastrar Colaborador',
                carregando: _salvando,
                aoClicar: _salvar,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormularioTreinamento extends StatefulWidget {
  const _FormularioTreinamento({required this.auth});

  final AuthService auth;

  @override
  State<_FormularioTreinamento> createState() => _FormularioTreinamentoState();
}

class _FormularioTreinamentoState extends State<_FormularioTreinamento> {
  late final TreinamentoService _api = TreinamentoService(widget.auth);
  final _codigo = TextEditingController();
  final _nome = TextEditingController();
  final _classificacao = TextEditingController();
  final _nr = TextEditingController();
  final _cargaHoraria = TextEditingController();
  final _validadeMeses = TextEditingController();
  String _status = 'Ativo';
  bool _salvando = false;

  Future<void> _salvar() async {
    if (_salvando) return;

    final validade = _validadeMeses.text.trim().isEmpty
        ? null
        : int.tryParse(_validadeMeses.text.trim());

    if (!Validacao.treinamento(
      codigo: _codigo.text.trim(),
      nome: _nome.text.trim(),
      classificacao: _classificacao.text.trim(),
      nr: _nr.text.trim(),
      cargaHoraria: _cargaHoraria.text.trim(),
      validadeMeses: validade,
      status: _status,
    )) {
      Toast.erro(context, 'Confira os campos e a validade inteira não negativa dentro dos limites.');
      return;
    }

    setState(() => _salvando = true);
    try {
      await _api.criar({
        'codigo': _codigo.text.trim(),
        'nome': _nome.text.trim(),
        'classificacao': _classificacao.text.trim(),
        'nr': _nr.text.trim().isEmpty ? null : _nr.text.trim(),
        'cargaHoraria': _cargaHoraria.text.trim(),
        'validadeMeses': validade,
        'status': _status,
      });
      if (!mounted) return;
      for (final c in [_codigo, _nome, _classificacao, _nr, _cargaHoraria, _validadeMeses]) {
        c.clear();
      }
      setState(() => _status = 'Ativo');
      Toast.sucesso(context, 'Treinamento cadastrado com sucesso!');
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        CartaoSecao(
          titulo: 'Novo Treinamento',
          subtitulo: 'NR e validade em meses são opcionais',
          child: Column(
            children: [
              CampoTexto(rotulo: 'Código', controlador: _codigo, maxCaracteres: 30),
              const SizedBox(height: 12),
              CampoTexto(rotulo: 'Nome', controlador: _nome, maxCaracteres: 180),
              const SizedBox(height: 12),
              CampoTexto(
                rotulo: 'Classificação',
                controlador: _classificacao,
                maxCaracteres: 60,
              ),
              const SizedBox(height: 12),
              CampoTexto(
                rotulo: 'NR',
                controlador: _nr,
                maxCaracteres: 60,
                dica: 'Ex.: NR-35',
              ),
              const SizedBox(height: 12),
              CampoTexto(rotulo: 'Carga horária', controlador: _cargaHoraria, maxCaracteres: 30),
              const SizedBox(height: 12),
              CampoTexto(
                rotulo: 'Validade (meses)',
                controlador: _validadeMeses,
                tipoTeclado: TextInputType.number,
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
              const SizedBox(height: 18),
              BotaoPrimario(
                rotulo: 'Cadastrar Treinamento',
                carregando: _salvando,
                aoClicar: _salvar,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormularioEpi extends StatefulWidget {
  const _FormularioEpi({required this.auth});

  final AuthService auth;

  @override
  State<_FormularioEpi> createState() => _FormularioEpiState();
}

class _FormularioEpiState extends State<_FormularioEpi> {
  late final EpiService _api = EpiService(widget.auth);
  final _descricao = TextEditingController();
  final _ca = TextEditingController();
  final _quantidade = TextEditingController(text: '0');
  String _inclusao = '';
  String _validade = '';
  bool _salvando = false;

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
      Toast.erro(
        context,
        'Confira os campos, datas e quantidade inteira não negativa dentro dos limites.',
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      await _api.cadastrarEpi({
        'descricao': _descricao.text.trim(),
        'ca': _ca.text.trim(),
        'quantidade': quantidade,
        'inclusao': _inclusao,
        'validade': _validade,
      });
      if (!mounted) return;
      _descricao.clear();
      _ca.clear();
      _quantidade.text = '0';
      setState(() {
        _inclusao = '';
        _validade = '';
      });
      Toast.sucesso(context, 'EPI cadastrado com sucesso!');
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        CartaoSecao(
          titulo: 'Novo EPI',
          subtitulo: 'Estoque inicial e datas de controle',
          child: Column(
            children: [
              CampoTexto(rotulo: 'Descrição', controlador: _descricao, maxCaracteres: 180),
              const SizedBox(height: 12),
              CampoTexto(
                rotulo: 'Número do CA',
                controlador: _ca,
                maxCaracteres: 30,
                tipoTeclado: TextInputType.number,
              ),
              const SizedBox(height: 12),
              CampoTexto(
                rotulo: 'Quantidade em estoque',
                controlador: _quantidade,
                tipoTeclado: TextInputType.number,
              ),
              const SizedBox(height: 12),
              CampoData(
                rotulo: 'Data de inclusão',
                valor: _inclusao,
                aoEscolher: (v) => setState(() => _inclusao = v),
              ),
              const SizedBox(height: 12),
              CampoData(
                rotulo: 'Validade (CA)',
                valor: _validade,
                primeira: Formato.paraData(_inclusao) ?? DateTime(2000),
                aoEscolher: (v) => setState(() => _validade = v),
              ),
              const SizedBox(height: 18),
              BotaoPrimario(
                rotulo: 'Cadastrar EPI',
                carregando: _salvando,
                aoClicar: _salvar,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Chips de sugestão para os campos que o web preenche com `datalist`.
class _Sugestoes extends StatelessWidget {
  const _Sugestoes({required this.opcoes, required this.aoEscolher});

  final List<String> opcoes;
  final ValueChanged<String> aoEscolher;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: opcoes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) => ActionChip(
          label: Text(opcoes[i], style: const TextStyle(fontSize: 12)),
          onPressed: () => aoEscolher(opcoes[i]),
          backgroundColor: AppCores.pagina,
          side: const BorderSide(color: AppCores.hairline),
        ),
      ),
    );
  }
}
