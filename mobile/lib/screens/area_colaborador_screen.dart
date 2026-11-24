import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatadores.dart';
import '../models/colaborador.dart';
import '../models/epi.dart';
import '../services/auth_service.dart';
import '../services/colaborador_service.dart';
import '../services/epi_service.dart';
import '../widgets/cartao_secao.dart';
import '../widgets/estado_tela.dart';
import '../widgets/sgsst_scaffold.dart';

const _semVinculo =
    'Não localizamos um cadastro de colaborador vinculado ao seu login. '
    'Procure o SESMT para conferir sua matrícula.';

/// Porta de `src/app/tela-area-colaborador`: resumo, certificações e
/// reciclagens (dados fixos, como no web) e os EPIs realmente entregues ao
/// colaborador logado.
class AreaColaboradorScreen extends StatefulWidget {
  const AreaColaboradorScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<AreaColaboradorScreen> createState() => _AreaColaboradorScreenState();
}

class _AreaColaboradorScreenState extends State<AreaColaboradorScreen> {
  late final ColaboradorService _apiColaboradores = ColaboradorService(widget.auth);
  late final EpiService _apiEpis = EpiService(widget.auth);

  // Blocos fixos portados do web (ainda sem persistência no backend).
  final List<({String treinamento, String validade, String status})> _certificacoes = [
    (treinamento: 'NR-35 Trabalho em Altura', validade: '10/07/2026', status: 'Vencida'),
  ];
  final List<({String treinamento, String prazo, String link})> _reciclagens = [
    (
      treinamento: 'NR-35 Trabalho em Altura',
      prazo: '12/06/2026',
      link: 'https://youtube.com',
    ),
  ];

  List<EntregaEpi> _meusEpis = const [];
  bool _carregando = true;
  String _aviso = '';

  @override
  void initState() {
    super.initState();
    _carregarMeusEpis();
  }

  Future<void> _carregarMeusEpis() async {
    setState(() {
      _carregando = true;
      _aviso = '';
    });
    try {
      // Não existe FK usuário↔colaborador: casamos a matrícula do login (ou o
      // e-mail, quando o login é um e-mail) com o cadastro de colaboradores.
      final colaboradores = await _apiColaboradores.listar();
      final colaborador = _resolverColaborador(colaboradores);

      if (colaborador == null) {
        if (!mounted) return;
        setState(() {
          _meusEpis = const [];
          _aviso = _semVinculo;
        });
        return;
      }

      final entregas = await _apiEpis.obterEntregas(colaboradorId: colaborador.id);
      if (!mounted) return;
      setState(() {
        _meusEpis = entregas;
        _aviso = entregas.isEmpty ? 'Nenhum EPI registrado no momento.' : '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _aviso = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Colaborador? _resolverColaborador(List<Colaborador> colaboradores) {
    final chave = widget.auth.sessao?.login.trim().toLowerCase();
    if (chave == null || chave.isEmpty) return null;
    String normalizar(String v) => v.trim().toLowerCase();

    for (final c in colaboradores) {
      if (normalizar(c.matricula) == chave) return c;
    }
    for (final c in colaboradores) {
      if (normalizar(c.email) == chave) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SgsstScaffold(
      titulo: 'Área do Colaborador',
      subtitulo: widget.auth.sessao?.nomeCompleto ?? '',
      child: RefreshIndicator(
        onRefresh: _carregarMeusEpis,
        color: AppCores.petroleo,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                _Indicador(rotulo: 'Certificações', valor: '${_certificacoes.length}'),
                const SizedBox(width: 10),
                _Indicador(rotulo: 'Reciclagens', valor: '${_reciclagens.length}'),
                const SizedBox(width: 10),
                _Indicador(rotulo: 'Meus EPIs', valor: '${_meusEpis.length}'),
              ],
            ),
            const SizedBox(height: 12),
            CartaoSecao(
              titulo: 'Minhas certificações',
              child: Column(
                children: [
                  for (final c in _certificacoes) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.treinamento,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppCores.tinta,
                                ),
                              ),
                              Text('Validade: ${c.validade}',
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        Etiqueta.situacao(c.status),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            CartaoSecao(
              titulo: 'Reciclagens e materiais',
              child: Column(
                children: [
                  for (final r in _reciclagens) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.treinamento,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppCores.tinta,
                                ),
                              ),
                              Text('Prazo limite: ${r.prazo}',
                                  style: Theme.of(context).textTheme.bodyMedium),
                              Text(r.link,
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            CartaoSecao(
              titulo: 'Meus EPIs',
              subtitulo: 'Entregas registradas no seu nome',
              child: _carregando
                  ? const EstadoCarregando()
                  : _meusEpis.isEmpty
                      ? EstadoVazio(
                          mensagem:
                              _aviso.isEmpty ? 'Nenhum EPI registrado no momento.' : _aviso,
                          icone: Icons.shield_outlined,
                        )
                      : Column(
                          children: [
                            for (final e in _meusEpis) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      e.epi,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppCores.tinta,
                                      ),
                                    ),
                                  ),
                                  Text('${e.quantidade} un',
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              LinhaDetalhe(rotulo: 'CA', valor: Formato.texto(e.ca)),
                              LinhaDetalhe(
                                rotulo: 'Data da entrega',
                                valor: Formato.data(e.dataEntrega),
                              ),
                              LinhaDetalhe(rotulo: 'Assinatura', valor: e.assinatura),
                              if (e != _meusEpis.last) const Divider(height: 18),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CartaoSgsst(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppCores.petroleo,
                ),
              ),
              Text(
                rotulo,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
