import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatadores.dart';
import '../core/toast.dart';
import '../models/chamado.dart';
import '../services/auth_service.dart';
import '../services/chamado_service.dart';
import '../widgets/campo_formulario.dart';
import '../widgets/cartao_secao.dart';
import '../widgets/estado_tela.dart';
import '../widgets/sgsst_scaffold.dart';

/// Porta de `src/app/tela-ajuda-suporte-colaborador`: o colaborador abre
/// solicitações e acompanha somente as próprias (GET /api/chamados?meus=true).
class AjudaSuporteColaboradorScreen extends StatefulWidget {
  const AjudaSuporteColaboradorScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<AjudaSuporteColaboradorScreen> createState() =>
      _AjudaSuporteColaboradorScreenState();
}

class _AjudaSuporteColaboradorScreenState extends State<AjudaSuporteColaboradorScreen> {
  late final ChamadoService _api = ChamadoService(widget.auth);

  String _tipo = 'Solicitar Ajuda';
  final _descricao = TextEditingController();
  List<Chamado> _solicitacoes = const [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await _api.listar(meus: true);
      if (!mounted) return;
      setState(() => _solicitacoes = lista);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _enviar() async {
    final descricao = _descricao.text.trim();
    if (descricao.isEmpty) {
      Toast.erro(context, 'Preencha a descrição da solicitação.');
      return;
    }

    try {
      final criado = await _api.criar(
        tipo: _tipo.contains('Ajuda') ? 'Ajuda' : 'Erro',
        descricao: descricao,
      );
      if (!mounted) return;
      setState(() {
        _solicitacoes = [criado, ..._solicitacoes];
        _descricao.clear();
      });
      Toast.sucesso(context, 'Solicitação enviada com sucesso!');
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SgsstScaffold(
      titulo: 'Ajuda e Suporte',
      subtitulo: 'Minhas solicitações',
      child: RefreshIndicator(
        onRefresh: _carregar,
        color: AppCores.petroleo,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            CartaoSecao(
              titulo: 'Nova solicitação',
              child: Column(
                children: [
                  CampoSelecao<String>(
                    rotulo: 'Tipo',
                    valor: _tipo,
                    opcoes: const [
                      DropdownMenuItem(value: 'Solicitar Ajuda', child: Text('Solicitar Ajuda')),
                      DropdownMenuItem(value: 'Reportar Erro', child: Text('Reportar Erro')),
                    ],
                    aoMudar: (v) => setState(() => _tipo = v ?? _tipo),
                  ),
                  const SizedBox(height: 12),
                  CampoTexto(
                    rotulo: 'Descrição',
                    controlador: _descricao,
                    maxLinhas: 4,
                  ),
                  const SizedBox(height: 14),
                  BotaoPrimario(
                    rotulo: 'Enviar',
                    icone: Icons.send_outlined,
                    aoClicar: _enviar,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_erro != null)
              EstadoErro(mensagem: _erro!, aoTentarNovamente: _carregar)
            else if (_carregando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: EstadoCarregando(mensagem: 'Carregando solicitações...'),
              )
            else
              CartaoSecao(
                titulo: 'Minhas solicitações',
                subtitulo: '${_solicitacoes.length} registro(s)',
                child: _solicitacoes.isEmpty
                    ? const EstadoVazio(
                        mensagem: 'Nenhuma solicitação registrada.',
                        icone: Icons.support_agent,
                      )
                    : Column(
                        children: [
                          for (final c in _solicitacoes) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.descricao,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppCores.tinta,
                                    ),
                                  ),
                                ),
                                Etiqueta(
                                  texto: c.status,
                                  cor: switch (c.status) {
                                    'Concluída' => AppCores.valido,
                                    'Cancelada' => AppCores.vencido,
                                    _ => AppCores.vencendo,
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinhaDetalhe(rotulo: 'Tipo', valor: c.tipo),
                            LinhaDetalhe(rotulo: 'Aberto em', valor: Formato.dataHora(c.abertoEm)),
                            if (c != _solicitacoes.last) const Divider(height: 18),
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
