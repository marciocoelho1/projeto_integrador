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

/// Porta de `src/app/tela-ajuda-suporte` (administrador): abre chamados e
/// administra o status de todos os solicitados.
class AjudaSuporteScreen extends StatefulWidget {
  const AjudaSuporteScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<AjudaSuporteScreen> createState() => _AjudaSuporteScreenState();
}

class _AjudaSuporteScreenState extends State<AjudaSuporteScreen> {
  late final ChamadoService _api = ChamadoService(widget.auth);

  String _tipo = 'Solicitar Ajuda';
  final _descricao = TextEditingController();
  List<Chamado> _solicitacoes = const [];
  bool _carregando = true;
  String? _erro;

  static const _statusOpcoes = ['Em andamento', 'Concluída', 'Cancelada'];

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
      final lista = await _api.listar();
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
      Toast.aviso(context, 'Preencha a descrição da solicitação.');
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

  Future<void> _mudarStatus(Chamado chamado, String status) async {
    if (status == chamado.status) return;

    try {
      final atualizado = await _api.atualizarStatus(
        id: chamado.id,
        tipo: chamado.tipo,
        descricao: chamado.descricao,
        status: status,
      );
      if (!mounted) return;
      setState(() {
        _solicitacoes = _solicitacoes
            .map((c) => c.id == atualizado.id ? atualizado : c)
            .toList();
      });
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SgsstScaffold(
      embutido: true,
      titulo: 'Ajuda e Suporte',
      subtitulo: 'Chamados de ajuda e erros',
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
                    dica: 'Descreva a necessidade ou o problema',
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
                titulo: 'Solicitações',
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
                                  texto: c.tipo,
                                  cor: c.tipo == 'Ajuda' ? AppCores.petroleo : AppCores.vencendo,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinhaDetalhe(rotulo: 'Solicitante', valor: c.solicitante),
                            LinhaDetalhe(rotulo: 'Aberto em', valor: Formato.dataHora(c.abertoEm)),
                            LinhaDetalhe(
                              rotulo: 'Concluído em',
                              valor: Formato.dataHora(c.concluidoEm),
                            ),
                            const SizedBox(height: 6),
                            CampoSelecao<String>(
                              rotulo: 'Status',
                              valor: c.status,
                              opcoes: [
                                for (final s in _statusOpcoes)
                                  DropdownMenuItem(value: s, child: Text(s)),
                              ],
                              aoMudar: (s) => _mudarStatus(c, s ?? c.status),
                            ),
                            if (c != _solicitacoes.last) const Divider(height: 22),
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
