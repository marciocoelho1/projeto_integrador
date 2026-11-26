import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatadores.dart';
import '../core/toast.dart';
import '../core/validacao.dart';
import '../models/colaborador.dart';
import '../models/treinamento.dart';
import '../models/treinamento_avancado.dart';
import '../services/auth_service.dart';
import '../services/colaborador_service.dart';
import '../services/relatorio_service.dart';
import '../services/treinamento_avancado_service.dart';
import '../services/treinamento_service.dart';
import '../widgets/campo_formulario.dart';
import '../widgets/cartao_secao.dart';
import '../widgets/estado_tela.dart';
import '../widgets/sgsst_scaffold.dart';

/// Porta de `src/app/tela-matriz-treinamento`: cartões de resumo (Visão Geral,
/// LNT/Cargos, Treinamentos, Certificações, Reciclagens), alternância
/// colaborador/lista e edição por tipo de registro.
class MatrizTreinamentoScreen extends StatefulWidget {
  const MatrizTreinamentoScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<MatrizTreinamentoScreen> createState() => _MatrizTreinamentoScreenState();
}

/// Mesmos valores do componente web.
const _janelaAlertaDias = 60;
const _nrsMatriz = [
  ('nr06', 'NR-06'),
  ('nr11', 'NR-11'),
  ('nr12', 'NR-12'),
  ('nr17', 'NR-17'),
  ('nr35', 'NR-35'),
];

class _MatrizTreinamentoScreenState extends State<MatrizTreinamentoScreen> {
  late final TreinamentoService _api = TreinamentoService(widget.auth);
  late final TreinamentoAvancadoService _avancado =
      TreinamentoAvancadoService(widget.auth);
  late final ColaboradorService _apiColaboradores = ColaboradorService(widget.auth);

  String _card = 'Visão Geral';
  String _modo = 'lista';

  bool _carregando = true;
  bool _salvando = false;
  bool _exportando = false;
  String? _erro;

  List<Treinamento> _treinamentos = const [];
  List<VinculoTreinamento> _vinculos = const [];
  List<Certificacao> _certificacoes = const [];
  List<LntCargo> _cargosLnt = const [];
  List<LntColaborador> _lntColaboradores = const [];
  List<Reciclagem> _reciclagens = const [];
  List<TurmaReciclagem> _turmas = const [];

  List<Colaborador> _colaboradores = const [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  List<({String titulo, String icone, int? total})> get _resumos => [
        (titulo: 'Visão Geral', icone: '📊', total: null),
        (
          titulo: 'LNT / Cargos',
          icone: '📋',
          total: _cargosLnt.isEmpty ? null : _cargosLnt.length,
        ),
        (titulo: 'Treinamentos', icone: '🎓', total: _treinamentos.length),
        (
          titulo: 'Certificações',
          icone: '🏅',
          total: _certificacoes.isEmpty ? null : _certificacoes.length,
        ),
        (
          titulo: 'Reciclagens',
          icone: '🔄',
          total: (_reciclagens.length + _turmas.length) == 0
              ? null
              : _reciclagens.length + _turmas.length,
        ),
      ];

  bool get _modoLista => _modo == 'lista';

  /// Exporta a matriz cruzada em CSV (`GET /api/relatorios/matriz-treinamentos.csv`),
  /// igual ao botao "Exportar Matriz" do web: o arquivo traz todos os vinculos
  /// gravados no banco, e nao apenas o que a Visao Geral carregou na tela.
  Future<void> _exportarMatriz() async {
    setState(() => _exportando = true);
    try {
      final csv = await RelatorioService(widget.auth).baixar('matriz-treinamentos');
      final caminho = await salvarCsv(csv, 'matriz-treinamentos.csv');
      if (!mounted) return;
      Toast.sucesso(context, 'Matriz cruzada exportada em CSV.\n$caminho');
    } catch (_) {
      if (!mounted) return;
      Toast.erro(context, 'Não foi possível gerar o relatório agora.');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      switch (_card) {
        case 'Treinamentos':
          if (_modoLista) {
            _treinamentos = await _api.listar();
          } else {
            _vinculos = await _avancado.listarVinculos();
          }
        case 'Visão Geral':
          final resultados = await Future.wait([
            _avancado.listarLnt(),
            _avancado.listarLntColaboradores(),
            _avancado.listarVinculos(),
          ]);
          _cargosLnt = resultados[0] as List<LntCargo>;
          _lntColaboradores = resultados[1] as List<LntColaborador>;
          _vinculos = resultados[2] as List<VinculoTreinamento>;
        case 'LNT / Cargos':
          if (_modoLista) {
            _cargosLnt = await _avancado.listarLnt();
          } else {
            _lntColaboradores = await _avancado.listarLntColaboradores();
          }
        case 'Certificações':
          _certificacoes = await _avancado.listarCertificacoes();
        case 'Reciclagens':
          if (_modoLista) {
            _turmas = await _avancado.listarTurmasReciclagem();
          } else {
            _reciclagens = await _avancado.listarReciclagens();
          }
      }
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _carregarReferencias() async {
    if (_colaboradores.isNotEmpty) return;
    final resultados = await Future.wait([
      _apiColaboradores.listar(),
      _api.listar(),
    ]);
    _colaboradores = resultados[0] as List<Colaborador>;
    _treinamentos = resultados[1] as List<Treinamento>;
  }

  Future<void> _abrirNovaCertificacao() async {
    setState(() => _carregando = true);
    try {
      await _carregarReferencias();
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _NovaCertificacao(
          avancado: _avancado,
          colaboradores: _colaboradores,
          treinamentos: _treinamentos,
        ),
      );
      await _carregar();
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrirNovaReciclagem() async {
    setState(() => _carregando = true);
    try {
      await _carregarReferencias();
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _NovaTurma(
          avancado: _avancado,
          treinamentos: _treinamentos,
        ),
      );
      await _carregar();
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _editarTreinamento(Treinamento item) async {
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      final completo = await _api.buscarPorId(item.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _EditarTreinamento(api: _api, original: completo),
      );
      await _carregar();
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _editarVinculo(VinculoTreinamento item) async {
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      await _carregarReferencias();
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _EditarVinculo(avancado: _avancado, original: item),
      );
      await _carregar();
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _editarCertificacao(Certificacao item) async {
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _EditarCertificacao(avancado: _avancado, original: item),
      );
      await _carregar();
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _editarTurma(TurmaReciclagem item) async {
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _EditarTurma(avancado: _avancado, original: item),
      );
      await _carregar();
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  /// Registro calculado no cliente não é editável, como no web.
  void _avisoDerivado() {
    Toast.aviso(
      context,
      'Este registro é calculado a partir dos cargos, vínculos e certificações. '
      'Edite o cadastro de origem.',
    );
  }

  Future<void> _excluirTreinamento(Treinamento item) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir treinamento'),
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
      setState(() => _treinamentos = _treinamentos.where((t) => t.id != item.id).toList());
      Toast.sucesso(context, 'Registro excluído com sucesso!');
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  List<({String colaborador, String cargo, Map<String, String> nrs})> get _matrizCruzada {
    return _lntColaboradores.map((colaborador) {
      final matrizDoCargo =
          _cargosLnt.where((c) => c.cargo == colaborador.cargo).firstOrNull;
      final nrs = <String, String>{};
      for (final (chave, nr) in _nrsMatriz) {
        nrs[chave] =
            _statusDaNr(nr, matrizDoCargo, colaborador.colaboradorId, _vinculos);
      }
      return (colaborador: colaborador.colaborador, cargo: colaborador.cargo, nrs: nrs);
    }).toList();
  }

  String _statusDaNr(
    String nr,
    LntCargo? matrizDoCargo,
    int colaboradorId,
    List<VinculoTreinamento> vinculos,
  ) {
    final exigido = (matrizDoCargo?.treinamentos ?? const <CargoTreinamentoItem>[])
        .where((t) => t.obrigatorio && (t.nr ?? '').toUpperCase().contains(nr))
        .firstOrNull;
    if (exigido == null) return 'N/A';

    final vinculo = vinculos
        .where((v) => v.colaboradorId == colaboradorId && v.treinamentoId == exigido.treinamentoId)
        .firstOrNull;
    if (vinculo == null) return 'Vencido';
    if (vinculo.status != 'Concluído') return 'Alerta';
    if (vinculo.validade == null || vinculo.validade!.isEmpty) return 'OK';

    final dias = _diasAte(vinculo.validade!);
    if (dias < 0) return 'Vencido';
    return dias <= _janelaAlertaDias ? 'Alerta' : 'OK';
  }

  int _diasAte(String data) {
    final alvo = DateTime.parse('${data}T00:00:00');
    final hoje = DateTime.now();
    final hojeZero = DateTime(hoje.year, hoje.month, hoje.day);
    return (alvo.difference(hojeZero).inHours / 24).round();
  }

  @override
  Widget build(BuildContext context) {
    return SgsstScaffold(
      titulo: 'Matriz de Treinamentos',
      subtitulo: 'LNT, certificações e reciclagens',
      // Mesma acao "Exportar Matriz" do web.
      acao: _exportando
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          : IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'Exportar Matriz',
              onPressed: _exportarMatriz,
            ),
      child: RefreshIndicator(
        onRefresh: _carregar,
        color: AppCores.petroleo,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // Altura da faixa de cards: o titulo do card pode ocupar duas linhas
            // (ex.: "Matriz de Treinamentos"), entao 84 px estourava.
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _resumos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final resumo = _resumos[i];
                  final selecionado = resumo.titulo == _card;
                  return _CartaoResumo(
                    titulo: resumo.titulo,
                    icone: resumo.icone,
                    total: resumo.total,
                    selecionado: selecionado,
                    aoClicar: () {
                      setState(() => _card = resumo.titulo);
                      _carregar();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            if (_card != 'Visão Geral' && _card != 'Certificações')
              _AlternadorModo(
                modo: _modo,
                aoMudar: (modo) {
                  if (_modo == modo) return;
                  setState(() => _modo = modo);
                  _carregar();
                },
              ),
            if (_card == 'Certificações' || _card == 'Reciclagens' || _card == 'LNT / Cargos')
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    if (_card == 'Certificações')
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _abrirNovaCertificacao,
                          icon: const Icon(Icons.add),
                          label: const Text('Certificação'),
                        ),
                      ),
                    if (_card == 'Reciclagens' && _modoLista)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _abrirNovaReciclagem,
                          icon: const Icon(Icons.add),
                          label: const Text('Turma'),
                        ),
                      ),
                  ],
                ),
              ),
            if (_erro != null)
              EstadoErro(mensagem: _erro!, aoTentarNovamente: _carregar)
            else if (_carregando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: EstadoCarregando(mensagem: 'Carregando matriz...'),
              )
            else
              ..._conteudo(),
          ],
        ),
      ),
    );
  }

  List<Widget> _conteudo() {
    switch (_card) {
      case 'Visão Geral':
        return [
          CartaoSecao(
            titulo: 'Matriz cruzada por NR',
            subtitulo: 'Status de cada colaborador nas NRs obrigatórias',
            child: _matrizCruzada.isEmpty
                ? const EstadoVazio(mensagem: 'Nenhum colaborador na matriz.')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingTextStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppCores.petroleo,
                      ),
                      columns: [
                        const DataColumn(label: Text('Colaborador')),
                        for (final (_, nr) in _nrsMatriz) DataColumn(label: Text(nr)),
                      ],
                      rows: [
                        for (final linha in _matrizCruzada)
                          DataRow(cells: [
                            DataCell(SizedBox(
                              width: 150,
                              child: Text(
                                linha.colaborador,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            )),
                            for (final (chave, _) in _nrsMatriz)
                              DataCell(linha.nrs[chave] == 'N/A'
                                  ? const Text('-')
                                  : Etiqueta.situacao(linha.nrs[chave]!)),
                          ]),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          CartaoSecao(
            titulo: 'Cargos e pendências',
            subtitulo: '${_lntColaboradores.length} colaborador(es)',
            child: _lntColaboradores.isEmpty
                ? const EstadoVazio(mensagem: 'Nenhum cargo cadastrado.')
                : Column(
                    children: [
                      for (final c in _lntColaboradores) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.colaborador,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppCores.tinta,
                                    ),
                                  ),
                                  Text(c.cargo,
                                      style: Theme.of(context).textTheme.bodyMedium),
                                  Text(
                                    c.treinamentosPendentes.isEmpty
                                        ? 'Nenhuma pendência'
                                        : 'Pendentes: ${c.treinamentosPendentes.join(', ')}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Etiqueta.situacao(c.status),
                          ],
                        ),
                        if (c != _lntColaboradores.last) const Divider(height: 18),
                      ],
                    ],
                  ),
          ),
        ];

      case 'Treinamentos':
        if (_modoLista) {
          return [
            CartaoSecao(
              titulo: 'Treinamentos',
              subtitulo: '${_treinamentos.length} registro(s)',
              child: _treinamentos.isEmpty
                  ? const EstadoVazio(mensagem: 'Nenhum treinamento cadastrado.')
                  : Column(
                      children: [
                        for (final t in _treinamentos) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.nome,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppCores.tinta,
                                      ),
                                    ),
                                    Text(
                                      '${t.codigo} · ${t.classificacao}'
                                      '${t.nr == null || t.nr!.isEmpty ? '' : ' · ${t.nr}'}',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    Text(
                                      'Carga: ${t.cargaHoraria} · Validade: '
                                      '${t.validadeMeses ?? '-'} meses',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              Etiqueta(
                                texto: t.status,
                                cor: t.status == 'Ativo' ? AppCores.valido : AppCores.cinza,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              BotaoTexto(
                                rotulo: 'Editar',
                                icone: Icons.edit_outlined,
                                aoClicar: () => _editarTreinamento(t),
                              ),
                              BotaoTexto(
                                rotulo: 'Excluir',
                                icone: Icons.delete_outline,
                                cor: AppCores.vencido,
                                aoClicar: () => _excluirTreinamento(t),
                              ),
                            ],
                          ),
                          if (t != _treinamentos.last) const Divider(height: 18),
                        ],
                      ],
                    ),
            ),
          ];
        }
        return [
          CartaoSecao(
            titulo: 'Treinamentos por colaborador',
            subtitulo: '${_vinculos.length} vínculo(s)',
            child: _vinculos.isEmpty
                ? const EstadoVazio(mensagem: 'Nenhum vínculo de treinamento.')
                : Column(
                    children: [
                      for (final v in _vinculos) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.colaborador,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppCores.tinta,
                                    ),
                                  ),
                                  Text(v.treinamento,
                                      style: Theme.of(context).textTheme.bodyMedium),
                                  Text(
                                    'Conclusão: ${Formato.data(v.dataConclusao)} · '
                                    'Validade: ${Formato.data(v.validade)}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Etiqueta.situacao(v.status),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            BotaoTexto(
                              rotulo: 'Editar',
                              icone: Icons.edit_outlined,
                              aoClicar: () => _editarVinculo(v),
                            ),
                          ],
                        ),
                        if (v != _vinculos.last) const Divider(height: 18),
                      ],
                    ],
                  ),
          ),
        ];

      case 'LNT / Cargos':
        if (_modoLista) {
          return [
            CartaoSecao(
              titulo: 'LNT / Cargos',
              subtitulo: '${_cargosLnt.length} cargo(s)',
              child: _cargosLnt.isEmpty
                  ? const EstadoVazio(mensagem: 'Nenhum cargo cadastrado.')
                  : Column(
                      children: [
                        for (final c in _cargosLnt) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.cargo,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppCores.tinta,
                                      ),
                                    ),
                                    Text(c.setor,
                                        style: Theme.of(context).textTheme.bodyMedium),
                                    Text(
                                      c.obrigatorios.isEmpty
                                          ? 'Nenhum treinamento obrigatório'
                                          : c.obrigatorios.join(', '),
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              Etiqueta(
                                texto: c.status,
                                cor: c.status == 'Ativo' ? AppCores.valido : AppCores.cinza,
                              ),
                            ],
                          ),
                          if (c != _cargosLnt.last) const Divider(height: 18),
                        ],
                      ],
                    ),
            ),
          ];
        }
        return [
          CartaoSecao(
            titulo: 'LNT por colaborador',
            subtitulo: '${_lntColaboradores.length} registro(s)',
            child: _lntColaboradores.isEmpty
                ? const EstadoVazio(mensagem: 'Nenhum colaborador.')
                : Column(
                    children: [
                      for (final c in _lntColaboradores) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.colaborador,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppCores.tinta,
                                    ),
                                  ),
                                  Text('${c.cargo} · ${c.setor}',
                                      style: Theme.of(context).textTheme.bodyMedium),
                                  Text(
                                    c.treinamentosPendentes.isEmpty
                                        ? 'Nenhum'
                                        : 'Pendentes: ${c.treinamentosPendentes.join(', ')}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Etiqueta.situacao(c.status),
                          ],
                        ),
                        if (c != _lntColaboradores.last) const Divider(height: 18),
                      ],
                    ],
                  ),
          ),
        ];

      case 'Certificações':
        return [
          CartaoSecao(
            titulo: 'Certificações',
            subtitulo: '${_certificacoes.length} registro(s)',
            child: _certificacoes.isEmpty
                ? const EstadoVazio(mensagem: 'Nenhuma certificação cadastrada.')
                : Column(
                    children: [
                      for (final c in _certificacoes) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.colaborador,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppCores.tinta,
                                    ),
                                  ),
                                  Text(c.treinamento,
                                      style: Theme.of(context).textTheme.bodyMedium),
                                  Text(
                                    '${c.instituicao} · ${c.cargaHoraria} · '
                                    'Validade: ${Formato.data(c.validade)}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Etiqueta.situacao(c.status),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            BotaoTexto(
                              rotulo: 'Editar',
                              icone: Icons.edit_outlined,
                              aoClicar: () => _editarCertificacao(c),
                            ),
                          ],
                        ),
                        if (c != _certificacoes.last) const Divider(height: 18),
                      ],
                    ],
                  ),
          ),
        ];

      case 'Reciclagens':
        if (_modoLista) {
          return [
            CartaoSecao(
              titulo: 'Turmas de reciclagem',
              subtitulo: '${_turmas.length} turma(s)',
              child: _turmas.isEmpty
                  ? const EstadoVazio(mensagem: 'Nenhuma turma agendada.')
                  : Column(
                      children: [
                        for (final t in _turmas) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.treinamento,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppCores.tinta,
                                      ),
                                    ),
                                    Text(
                                      'Turma #${t.id} · Instrutor: ${t.instrutor}',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    Text(
                                      'Data: ${Formato.data(t.dataAgendada)} · '
                                      'Vagas: ${t.vagas}',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              Etiqueta.situacao(t.status),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              BotaoTexto(
                                rotulo: 'Editar',
                                icone: Icons.edit_outlined,
                                aoClicar: () => _editarTurma(t),
                              ),
                            ],
                          ),
                          if (t != _turmas.last) const Divider(height: 18),
                        ],
                      ],
                    ),
            ),
          ];
        }
        return [
          CartaoSecao(
            titulo: 'Reciclagens pendentes',
            subtitulo: 'Derivadas da validade dos vínculos',
            child: _reciclagens.isEmpty
                ? const EstadoVazio(mensagem: 'Nenhuma reciclagem pendente.')
                : Column(
                    children: [
                      for (final r in _reciclagens) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.colaborador,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppCores.tinta,
                                    ),
                                  ),
                                  Text(r.treinamento,
                                      style: Theme.of(context).textTheme.bodyMedium),
                                  Text(
                                    'Prazo: ${Formato.data(r.prazoMaximo)} · '
                                    '${r.diasRestantes} dia(s)',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Etiqueta.situacao(r.status),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            BotaoTexto(
                              rotulo: 'Por que não edita?',
                              icone: Icons.info_outline,
                              aoClicar: _avisoDerivado,
                            ),
                          ],
                        ),
                        if (r != _reciclagens.last) const Divider(height: 18),
                      ],
                    ],
                  ),
          ),
        ];
    }
    return const [];
  }
}

class _CartaoResumo extends StatelessWidget {
  const _CartaoResumo({
    required this.titulo,
    required this.icone,
    required this.total,
    required this.selecionado,
    required this.aoClicar,
  });

  final String titulo;
  final String icone;
  final int? total;
  final bool selecionado;
  final VoidCallback aoClicar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: aoClicar,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selecionado ? AppCores.petroleo : AppCores.cartao,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selecionado ? AppCores.petroleo : AppCores.hairline,
          ),
        ),
        // O titulo pode ocupar duas linhas; sem o MainAxisSize.min a Column
        // estourava 7 px dentro da altura fixa do card.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(icone, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                if (total != null)
                  Flexible(
                    child: Text(
                      '$total',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: selecionado ? Colors.white : AppCores.petroleo,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selecionado ? Colors.white : AppCores.tinta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlternadorModo extends StatelessWidget {
  const _AlternadorModo({required this.modo, required this.aoMudar});

  final String modo;
  final ValueChanged<String> aoMudar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'colaborador', label: Text('Por colaborador')),
          ButtonSegment(value: 'lista', label: Text('Lista')),
        ],
        selected: {modo},
        onSelectionChanged: (s) => aoMudar(s.first),
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          backgroundColor: WidgetStateProperty.resolveWith(
            (estados) => estados.contains(WidgetState.selected)
                ? AppCores.petroleo
                : Colors.white,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (estados) => estados.contains(WidgetState.selected)
                ? Colors.white
                : AppCores.petroleo,
          ),
        ),
      ),
    );
  }
}

class _EditarTreinamento extends StatefulWidget {
  const _EditarTreinamento({required this.api, required this.original});

  final TreinamentoService api;
  final Treinamento original;

  @override
  State<_EditarTreinamento> createState() => _EditarTreinamentoState();
}

class _EditarTreinamentoState extends State<_EditarTreinamento> {
  late final TextEditingController _codigo = TextEditingController(text: widget.original.codigo);
  late final TextEditingController _nome = TextEditingController(text: widget.original.nome);
  late final TextEditingController _classificacao =
      TextEditingController(text: widget.original.classificacao);
  late final TextEditingController _nr = TextEditingController(text: widget.original.nr ?? '');
  late final TextEditingController _cargaHoraria =
      TextEditingController(text: widget.original.cargaHoraria);
  late final TextEditingController _validade = TextEditingController(
    text: widget.original.validadeMeses?.toString() ?? '',
  );
  late String _status = widget.original.status;
  bool _salvando = false;

  @override
  void dispose() {
    for (final c in [_codigo, _nome, _classificacao, _nr, _cargaHoraria, _validade]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    final validade = _validade.text.trim().isEmpty ? null : int.tryParse(_validade.text.trim());

    if (!Validacao.treinamento(
      codigo: _codigo.text.trim(),
      nome: _nome.text.trim(),
      classificacao: _classificacao.text.trim(),
      nr: _nr.text.trim(),
      cargaHoraria: _cargaHoraria.text.trim(),
      validadeMeses: validade,
      status: _status,
    )) {
      Toast.erro(context, 'Preencha os campos corretamente.');
      return;
    }

    setState(() => _salvando = true);
    try {
      await widget.api.atualizar(widget.original.id, {
        'codigo': _codigo.text.trim(),
        'nome': _nome.text.trim(),
        'classificacao': _classificacao.text.trim(),
        'nr': _nr.text.trim().isEmpty ? null : _nr.text.trim(),
        'cargaHoraria': _cargaHoraria.text.trim(),
        'validadeMeses': validade,
        'status': _status,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      Toast.sucesso(context, 'Treinamento atualizado com sucesso!');
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FolhaModal(
      titulo: 'Editar treinamento',
      subtitulo: widget.original.nome,
      filhos: [
        CampoTexto(rotulo: 'Código', controlador: _codigo, maxCaracteres: 30),
        CampoTexto(rotulo: 'Nome', controlador: _nome, maxCaracteres: 180),
        CampoTexto(rotulo: 'Classificação', controlador: _classificacao, maxCaracteres: 60),
        CampoTexto(rotulo: 'NR', controlador: _nr, maxCaracteres: 60),
        CampoTexto(rotulo: 'Carga horária', controlador: _cargaHoraria, maxCaracteres: 30),
        CampoTexto(rotulo: 'Validade (meses)', controlador: _validade, tipoTeclado: TextInputType.number),
        CampoSelecao<String>(
          rotulo: 'Status',
          valor: _status,
          opcoes: const [
            DropdownMenuItem(value: 'Ativo', child: Text('Ativo')),
            DropdownMenuItem(value: 'Inativo', child: Text('Inativo')),
          ],
          aoMudar: (v) => setState(() => _status = v ?? _status),
        ),
      ],
      carregando: _salvando,
      aoSalvar: _salvar,
    );
  }
}

class _EditarVinculo extends StatefulWidget {
  const _EditarVinculo({required this.avancado, required this.original});

  final TreinamentoAvancadoService avancado;
  final VinculoTreinamento original;

  @override
  State<_EditarVinculo> createState() => _EditarVinculoState();
}

class _EditarVinculoState extends State<_EditarVinculo> {
  late String _dataConclusao = widget.original.dataConclusao ?? '';
  late String _status = widget.original.status;
  bool _salvando = false;

  Future<void> _salvar() async {
    if (_salvando) return;

    if (!const ['Concluído', 'Em Andamento', 'Pendente'].contains(_status)) {
      Toast.erro(context, 'Selecione o status do vínculo.');
      return;
    }

    setState(() => _salvando = true);
    try {
      await widget.avancado.atualizarVinculo(widget.original.id, {
        'colaboradorId': widget.original.colaboradorId,
        'treinamentoId': widget.original.treinamentoId,
        'dataConclusao': _dataConclusao.isEmpty ? null : _dataConclusao,
        'status': _status,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      Toast.sucesso(context, 'Vínculo atualizado com sucesso!');
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FolhaModal(
      titulo: 'Editar vínculo',
      subtitulo: '${widget.original.colaborador} · ${widget.original.treinamento}',
      filhos: [
        CampoData(
          rotulo: 'Data de conclusão',
          valor: _dataConclusao,
          aoEscolher: (v) => setState(() => _dataConclusao = v),
        ),
        CampoSelecao<String>(
          rotulo: 'Status',
          valor: _status,
          opcoes: const [
            DropdownMenuItem(value: 'Concluído', child: Text('Concluído')),
            DropdownMenuItem(value: 'Em Andamento', child: Text('Em Andamento')),
            DropdownMenuItem(value: 'Pendente', child: Text('Pendente')),
          ],
          aoMudar: (v) => setState(() => _status = v ?? _status),
        ),
      ],
      carregando: _salvando,
      aoSalvar: _salvar,
    );
  }
}

class _EditarCertificacao extends StatefulWidget {
  const _EditarCertificacao({required this.avancado, required this.original});

  final TreinamentoAvancadoService avancado;
  final Certificacao original;

  @override
  State<_EditarCertificacao> createState() => _EditarCertificacaoState();
}

class _EditarCertificacaoState extends State<_EditarCertificacao> {
  late final TextEditingController _instituicao =
      TextEditingController(text: widget.original.instituicao);
  late final TextEditingController _cargaHoraria =
      TextEditingController(text: widget.original.cargaHoraria);
  late String _validade = widget.original.validade;
  bool _salvando = false;

  @override
  void dispose() {
    _instituicao.dispose();
    _cargaHoraria.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando) return;

    if (_instituicao.text.trim().isEmpty ||
        _cargaHoraria.text.trim().isEmpty ||
        _validade.isEmpty) {
      Toast.erro(context, 'Informe instituição, carga horária e validade.');
      return;
    }

    setState(() => _salvando = true);
    try {
      await widget.avancado.atualizarCertificacao(widget.original.id, {
        'colaboradorId': widget.original.colaboradorId,
        'treinamentoId': widget.original.treinamentoId,
        'instituicao': _instituicao.text.trim(),
        'cargaHoraria': _cargaHoraria.text.trim(),
        'emitidaEm': widget.original.emitidaEm,
        'validade': _validade,
        'arquivoUrl': null,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      Toast.sucesso(context, 'Certificação atualizada com sucesso!');
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FolhaModal(
      titulo: 'Editar certificação',
      subtitulo: '${widget.original.colaborador} · ${widget.original.treinamento}',
      filhos: [
        CampoTexto(rotulo: 'Instituição', controlador: _instituicao, maxCaracteres: 120),
        CampoTexto(rotulo: 'Carga horária', controlador: _cargaHoraria, maxCaracteres: 30),
        CampoData(
          rotulo: 'Validade',
          valor: _validade,
          aoEscolher: (v) => setState(() => _validade = v),
        ),
      ],
      carregando: _salvando,
      aoSalvar: _salvar,
    );
  }
}

class _EditarTurma extends StatefulWidget {
  const _EditarTurma({required this.avancado, required this.original});

  final TreinamentoAvancadoService avancado;
  final TurmaReciclagem original;

  @override
  State<_EditarTurma> createState() => _EditarTurmaState();
}

class _EditarTurmaState extends State<_EditarTurma> {
  late final TextEditingController _instrutor =
      TextEditingController(text: widget.original.instrutor);
  late final TextEditingController _vagas =
      TextEditingController(text: '${widget.original.vagas}');
  late String _dataAgendada = widget.original.dataAgendada;
  late String _status = widget.original.status;
  bool _salvando = false;

  @override
  void dispose() {
    _instrutor.dispose();
    _vagas.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando) return;

    final vagas = int.tryParse(_vagas.text.trim());
    if (_instrutor.text.trim().isEmpty ||
        _dataAgendada.isEmpty ||
        vagas == null ||
        vagas < 0) {
      Toast.erro(context, 'Informe instrutor, data agendada e vagas (0 ou mais).');
      return;
    }

    setState(() => _salvando = true);
    try {
      await widget.avancado.atualizarTurmaReciclagem(widget.original.id, {
        'treinamentoId': widget.original.treinamentoId,
        'instrutor': _instrutor.text.trim(),
        'dataAgendada': _dataAgendada,
        'vagas': vagas,
        'status': _status,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      Toast.sucesso(context, 'Turma de reciclagem atualizada com sucesso!');
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FolhaModal(
      titulo: 'Editar turma de reciclagem',
      subtitulo: widget.original.treinamento,
      filhos: [
        CampoTexto(rotulo: 'Instrutor', controlador: _instrutor, maxCaracteres: 120),
        CampoData(
          rotulo: 'Data agendada',
          valor: _dataAgendada,
          aoEscolher: (v) => setState(() => _dataAgendada = v),
        ),
        CampoTexto(rotulo: 'Vagas', controlador: _vagas, tipoTeclado: TextInputType.number),
        CampoSelecao<String>(
          rotulo: 'Status',
          valor: _status,
          opcoes: const [
            DropdownMenuItem(value: 'Agendada', child: Text('Agendada')),
            DropdownMenuItem(value: 'Concluída', child: Text('Concluída')),
            DropdownMenuItem(value: 'Cancelada', child: Text('Cancelada')),
          ],
          aoMudar: (v) => setState(() => _status = v ?? _status),
        ),
      ],
      carregando: _salvando,
      aoSalvar: _salvar,
    );
  }
}

class _NovaCertificacao extends StatefulWidget {
  const _NovaCertificacao({
    required this.avancado,
    required this.colaboradores,
    required this.treinamentos,
  });

  final TreinamentoAvancadoService avancado;
  final List<Colaborador> colaboradores;
  final List<Treinamento> treinamentos;

  @override
  State<_NovaCertificacao> createState() => _NovaCertificacaoState();
}

class _NovaCertificacaoState extends State<_NovaCertificacao> {
  int? _colaboradorId;
  int? _treinamentoId;
  final _instituicao = TextEditingController();
  final _cargaHoraria = TextEditingController();
  String _emitidaEm = '';
  String _validade = '';
  bool _salvando = false;

  @override
  void dispose() {
    _instituicao.dispose();
    _cargaHoraria.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando) return;

    if (_colaboradorId == null ||
        _treinamentoId == null ||
        _instituicao.text.trim().isEmpty ||
        _cargaHoraria.text.trim().isEmpty ||
        _emitidaEm.isEmpty ||
        _validade.isEmpty) {
      Toast.erro(context, 'Informe colaborador, treinamento, instituição, carga horária e as datas.');
      return;
    }

    setState(() => _salvando = true);
    try {
      await widget.avancado.criarCertificacao({
        'colaboradorId': _colaboradorId,
        'treinamentoId': _treinamentoId,
        'instituicao': _instituicao.text.trim(),
        'cargaHoraria': _cargaHoraria.text.trim(),
        'emitidaEm': _emitidaEm,
        'validade': _validade,
        'arquivoUrl': null,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      Toast.sucesso(context, 'Certificação cadastrada com sucesso!');
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FolhaModal(
      titulo: 'Nova certificação',
      subtitulo: 'Vincular certificação a um colaborador',
      filhos: [
        CampoSelecao<int>(
          rotulo: 'Colaborador',
          valor: _colaboradorId,
          opcoes: [
            for (final c in widget.colaboradores)
              DropdownMenuItem(value: c.id, child: Text(c.nome, overflow: TextOverflow.ellipsis)),
          ],
          aoMudar: (v) => setState(() => _colaboradorId = v),
        ),
        CampoSelecao<int>(
          rotulo: 'Treinamento',
          valor: _treinamentoId,
          opcoes: [
            for (final t in widget.treinamentos)
              DropdownMenuItem(value: t.id, child: Text(t.nome, overflow: TextOverflow.ellipsis)),
          ],
          aoMudar: (v) => setState(() => _treinamentoId = v),
        ),
        CampoTexto(rotulo: 'Instituição', controlador: _instituicao, maxCaracteres: 120),
        CampoTexto(rotulo: 'Carga horária', controlador: _cargaHoraria, maxCaracteres: 30),
        CampoData(
          rotulo: 'Emitida em',
          valor: _emitidaEm,
          aoEscolher: (v) => setState(() => _emitidaEm = v),
        ),
        CampoData(
          rotulo: 'Validade',
          valor: _validade,
          aoEscolher: (v) => setState(() => _validade = v),
        ),
      ],
      carregando: _salvando,
      aoSalvar: _salvar,
    );
  }
}

class _NovaTurma extends StatefulWidget {
  const _NovaTurma({required this.avancado, required this.treinamentos});

  final TreinamentoAvancadoService avancado;
  final List<Treinamento> treinamentos;

  @override
  State<_NovaTurma> createState() => _NovaTurmaState();
}

class _NovaTurmaState extends State<_NovaTurma> {
  int? _treinamentoId;
  final _instrutor = TextEditingController();
  final _vagas = TextEditingController();
  String _dataAgendada = '';
  String _status = 'Agendada';
  bool _salvando = false;

  @override
  void dispose() {
    _instrutor.dispose();
    _vagas.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando) return;

    final vagas = int.tryParse(_vagas.text.trim());
    if (_treinamentoId == null ||
        _instrutor.text.trim().isEmpty ||
        _dataAgendada.isEmpty ||
        vagas == null ||
        vagas < 0) {
      Toast.erro(context, 'Informe treinamento, instrutor, data agendada e vagas (0 ou mais).');
      return;
    }

    setState(() => _salvando = true);
    try {
      await widget.avancado.criarTurmaReciclagem({
        'treinamentoId': _treinamentoId,
        'instrutor': _instrutor.text.trim(),
        'dataAgendada': _dataAgendada,
        'vagas': vagas,
        'status': _status,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      Toast.sucesso(context, 'Turma de reciclagem cadastrada com sucesso!');
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FolhaModal(
      titulo: 'Nova turma de reciclagem',
      subtitulo: 'Agendamento de turma',
      filhos: [
        CampoSelecao<int>(
          rotulo: 'Treinamento',
          valor: _treinamentoId,
          opcoes: [
            for (final t in widget.treinamentos)
              DropdownMenuItem(value: t.id, child: Text(t.nome, overflow: TextOverflow.ellipsis)),
          ],
          aoMudar: (v) => setState(() => _treinamentoId = v),
        ),
        CampoTexto(rotulo: 'Instrutor', controlador: _instrutor, maxCaracteres: 120),
        CampoData(
          rotulo: 'Data agendada',
          valor: _dataAgendada,
          aoEscolher: (v) => setState(() => _dataAgendada = v),
        ),
        CampoTexto(rotulo: 'Vagas', controlador: _vagas, tipoTeclado: TextInputType.number),
        CampoSelecao<String>(
          rotulo: 'Status',
          valor: _status,
          opcoes: const [
            DropdownMenuItem(value: 'Agendada', child: Text('Agendada')),
            DropdownMenuItem(value: 'Concluída', child: Text('Concluída')),
            DropdownMenuItem(value: 'Cancelada', child: Text('Cancelada')),
          ],
          aoMudar: (v) => setState(() => _status = v ?? _status),
        ),
      ],
      carregando: _salvando,
      aoSalvar: _salvar,
    );
  }
}

/// Folha modal padrão dos formulários de edição/cadastro.
class _FolhaModal extends StatelessWidget {
  const _FolhaModal({
    required this.titulo,
    required this.subtitulo,
    required this.filhos,
    required this.carregando,
    required this.aoSalvar,
  });

  final String titulo;
  final String subtitulo;
  final List<Widget> filhos;
  final bool carregando;
  final Future<void> Function() aoSalvar;

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
            Text(titulo, style: Theme.of(context).textTheme.titleLarge),
            Text(subtitulo, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            for (final (i, filho) in filhos.indexed) ...[
              filho,
              if (i != filhos.length - 1) const SizedBox(height: 12),
            ],
            const SizedBox(height: 20),
            BotaoPrimario(
              rotulo: 'Salvar',
              carregando: carregando,
              aoClicar: aoSalvar,
            ),
            TextButton(
              onPressed: carregando ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
