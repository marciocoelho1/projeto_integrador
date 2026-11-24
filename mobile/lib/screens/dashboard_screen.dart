import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../core/formatadores.dart';
import '../core/toast.dart';
import '../models/dashboard_dados.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../widgets/alerta_card.dart';
import '../widgets/blocos_dashboard.dart';
import '../widgets/conformidade_card.dart';
import '../widgets/kpi_card.dart';

/// Janela de 'a vencer', a mesma que o backend usa no DashboardService.
const int kJanelaAlertaDias = 30;

/// Painel inicial do perfil admin. Porta a tela `dashboard` do web: as sete fontes
/// carregam juntas e os oito blocos sao derivados no cliente, como no Angular.
class DashboardScreen extends StatefulWidget {
  final AuthService auth;
  final void Function(String destino)? aoNavegar;

  const DashboardScreen({super.key, required this.auth, this.aoNavegar});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  late final DashboardService _service = DashboardService(widget.auth);
  DadosDashboard? _dados;
  String? _erro;
  bool _carregando = true;
  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  /// Publico para o MainScreen conseguir recarregar ao voltar para a aba.
  Future<void> carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final dados = await _service.carregar();
      if (!mounted) return;
      setState(() {
        _dados = dados;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = '$e';
        _carregando = false;
      });
    }
  }

  /// Exporta o relatorio do servidor (GET /api/relatorios/dashboard.csv).
  Future<void> exportarRelatorio() async {
    setState(() => _exportando = true);
    try {
      final csv = await _service.baixarRelatorioCsv('dashboard');
      final caminho = await salvarCsv(csv, 'relatorio_dashboard.csv');
      if (!mounted) return;
      Toast.sucesso(context, 'Relatório do dashboard exportado em CSV.\n$caminho');
    } catch (_) {
      if (!mounted) return;
      Toast.erro(context, 'Não foi possível gerar o relatório agora.');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  void _ir(String destino) => widget.aoNavegar?.call(destino);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.areia,
      appBar: AppBar(
        backgroundColor: AppCores.petroleo,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Meu SGSST',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            Text('Indicadores de SST',
                style: TextStyle(fontSize: 12.5, color: Color(0xB3FFFFFF))),
          ],
        ),
        actions: [
          if (_dados != null)
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'Exportar',
              onPressed: _exportando ? null : exportarRelatorio,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar',
            onPressed: _carregando ? null : carregar,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await widget.auth.sair();
              if (context.mounted) Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: _corpo(),
    );
  }

  Widget _corpo() {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_erro!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppCores.vencido)),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: carregar, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }

    final d = _dados!;
    final indicadores = d.indicadores;
    final hora = DateFormat('dd/MM/yyyy HH:mm').format(indicadores.geradoEm);

    return RefreshIndicator(
      onRefresh: carregar,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text('Visão geral', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text('Atualizado em $hora', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),

          // Bloco 1 - KPIs em grade 2x2
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              KpiCard(
                rotulo: 'Colaboradores ativos',
                valor: '${indicadores.colaboradores.ativos}',
                sufixo: '/ ${indicadores.colaboradores.total}',
                dica: '${indicadores.colaboradores.afastados} afastados',
                cor: AppCores.petroleo,
              ),
              KpiCard(
                rotulo: 'EPIs em estoque',
                valor: '${indicadores.epis.emEstoque}',
                sufixo: 'un.',
                dica: '${indicadores.epis.vencidos} vencidas',
                cor: AppCores.vencido,
              ),
              KpiCard(
                rotulo: 'Certificações',
                valor: '${indicadores.certificacoes.ativas}',
                sufixo: 'ativas',
                dica: '${indicadores.certificacoes.vencendoEm30Dias} a vencer',
                cor: AppCores.vencendo,
              ),
              KpiCard(
                rotulo: 'EPIs entregues',
                valor: '${indicadores.epis.entreguesUltimos30Dias}',
                sufixo: '30 dias',
                dica: '${indicadores.epis.totalTipos} tipos',
                cor: AppCores.cinza,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bloco 2 - Precisa de atencao
          AlertaCard(alertas: indicadores.alertas),
          const SizedBox(height: 12),

          // Bloco 3 - Conformidade de treinamentos
          ConformidadeCard(treinamentos: indicadores.treinamentos),
          const SizedBox(height: 12),

          // Bloco 4 - Pendencias por NR e setor
          _matrizCalor(d),
          const SizedBox(height: 12),

          // Bloco 5 - Colaboradores por setor
          BlocoSetores(
            setores: _porSetor(d),
            aoVerTodos: () => _ir('colaboradores'),
          ),
          const SizedBox(height: 12),

          // Bloco 6 - EPIs em estoque critico
          _episCriticos(d),
          const SizedBox(height: 12),

          // Bloco 7 - Entregas de EPI
          _entregasPorMes(d),
          const SizedBox(height: 12),

          // Bloco 8 - Ultimas entregas
          BlocoUltimasEntregas(
            itens: _ultimasEntregas(d),
            aoVerTodas: () => _ir('epis'),
          ),
          const SizedBox(height: 12),

          // Bloco 9 - Atividade recente
          BlocoAtividadeRecente(
            eventos: _atividade(d),
            aoVerLog: () => _ir('configuracoes'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /* =======================================================
     Dados derivados (mesmas formulas do dashboard.ts do web)
     ======================================================= */

  String get _hojeIso {
    final agora = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(agora);
  }

  String get _limiteAlerta {
    final limite = DateTime.now().add(const Duration(days: kJanelaAlertaDias));
    return DateFormat('yyyy-MM-dd').format(limite);
  }

  /// Mapa id do treinamento -> NR, como o nrPorTreinamento do web.
  Map<int, String> _nrPorTreinamento(DadosDashboard d) => {
        for (final t in d.treinamentos)
          if (t.nr != null && t.nr!.isNotEmpty) t.id: t.nr!,
      };

  /// Bloco 4 - Pendencias por NR e setor (matriz calor).
  Widget _matrizCalor(DadosDashboard d) {
    final limite = _limiteAlerta;
    final nrPorTreinamento = _nrPorTreinamento(d);
    final setorPorColaborador = {
      for (final c in d.colaboradores)
        c.id: c.setor.isEmpty ? 'Sem setor' : c.setor,
    };

    final contagem = <String, int>{};
    final nrs = <String>{};

    for (final vinculo in d.vinculos) {
      final nr = nrPorTreinamento[vinculo.treinamentoId];
      if (nr == null) continue; // Sem NR nao ha coluna na matriz.
      final validade = vinculo.validade;
      if (validade == null || validade.isEmpty || validade.compareTo(limite) > 0) continue;

      final setor = setorPorColaborador[vinculo.colaboradorId] ?? 'Sem setor';
      nrs.add(nr);
      final chave = '$setor|$nr';
      contagem[chave] = (contagem[chave] ?? 0) + 1;
    }

    final colunas = nrs.toList()..sort();
    final setores = <String>{
      for (final c in d.colaboradores) c.setor.isEmpty ? 'Sem setor' : c.setor,
    }.toList();

    final linhas = setores.map((setor) {
      final valores = colunas
          .map((nr) => contagem['$setor|$nr'] ?? 0)
          .toList();
      return (
        setor: setor,
        valores: valores,
        total: valores.fold<int>(0, (soma, v) => soma + v),
      );
    }).toList()
      ..sort((a, b) => b.total != a.total ? b.total - a.total : a.setor.compareTo(b.setor));

    final totaisPorNr = List.generate(
      colunas.length,
      (i) => linhas.fold<int>(0, (soma, linha) => soma + linha.valores[i]),
    );

    return BlocoMatrizCalor(
      nrs: colunas,
      linhas: linhas,
      totaisPorNr: totaisPorNr,
      total: totaisPorNr.fold<int>(0, (soma, v) => soma + v),
      janelaAlertaDias: kJanelaAlertaDias,
    );
  }

  /// Bloco 5 - Colaboradores por setor.
  List<({String setor, int total})> _porSetor(DadosDashboard d) {
    final contagem = <String, int>{};
    for (final c in d.colaboradores) {
      final setor = c.setor.isEmpty ? 'Sem setor' : c.setor;
      contagem[setor] = (contagem[setor] ?? 0) + 1;
    }
    final linhas = contagem.entries
        .map((e) => (setor: e.key, total: e.value))
        .toList()
      ..sort((a, b) => b.total != a.total ? b.total - a.total : a.setor.compareTo(b.setor));
    return linhas;
  }

  /// Bloco 6 - EPIs em estoque critico.
  Widget _episCriticos(DadosDashboard d) {
    final hoje = _hojeIso;
    final criticos = d.epis
        .where((epi) => epi.quantidade <= kEstoqueMinimo)
        .map((epi) {
          final vencido = epi.validade.isNotEmpty && epi.validade.compareTo(hoje) < 0;
          final situacao = vencido
              ? 'Vencido'
              : epi.quantidade <= 3
                  ? 'Crítico'
                  : epi.quantidade == 4
                      ? 'Atenção'
                      : 'No mínimo';
          final cor = situacao == 'Vencido' || situacao == 'Crítico'
              ? AppCores.vencido
              : situacao == 'Atenção'
                  ? AppCores.vencendo
                  : AppCores.cinza;
          return (
            descricao: epi.descricao,
            ca: epi.ca,
            quantidade: epi.quantidade,
            situacao: situacao,
            cor: cor,
          );
        })
        .toList()
      ..sort((a, b) => a.quantidade != b.quantidade
          ? a.quantidade - b.quantidade
          : a.descricao.compareTo(b.descricao));

    return BlocoEpisCriticos(
      itens: criticos.take(kLimiteLista).toList(),
      restantes: criticos.length > kLimiteLista ? criticos.length - kLimiteLista : 0,
      aoRepor: () => _ir('epis'),
    );
  }

  /// Bloco 7 - Entregas de EPI nos ultimos 6 meses.
  Widget _entregasPorMes(DadosDashboard d) {
    final hoje = DateTime.now();
    final meses = <({String chave, String rotulo, int valor})>[];
    for (var indice = 0; indice < 6; indice++) {
      final referencia = DateTime(hoje.year, hoje.month - (5 - indice), 1);
      meses.add((
        chave: '${referencia.year}-${referencia.month.toString().padLeft(2, '0')}',
        rotulo: mesCurto(referencia.month),
        valor: 0,
      ));
    }

    for (final entrega in d.entregas) {
      final chave = entrega.dataEntrega.length >= 7
          ? entrega.dataEntrega.substring(0, 7)
          : entrega.dataEntrega;
      final indice = meses.indexWhere((m) => m.chave == chave);
      if (indice < 0) continue;
      final atual = meses[indice];
      meses[indice] = (chave: atual.chave, rotulo: atual.rotulo, valor: atual.valor + entrega.quantidade);
    }

    return BlocoEntregasMes(
      total: meses.fold<int>(0, (soma, m) => soma + m.valor),
      meses: meses.map((m) => (rotulo: m.rotulo, valor: m.valor)).toList(),
      aoVerEntregas: () => _ir('epis'),
    );
  }

  /// Bloco 8 - Ultimas entregas registradas.
  List<({String colaborador, String epi, int quantidade, String data, bool assinado})> _ultimasEntregas(
      DadosDashboard d) {
    final ordenadas = [...d.entregas]..sort((a, b) => b.dataEntrega.compareTo(a.dataEntrega));
    return ordenadas
        .take(kLimiteLista)
        .map((e) => (
              colaborador: e.colaborador,
              epi: e.epi,
              quantidade: e.quantidade,
              data: Formato.data(e.dataEntrega),
              assinado: e.assinatura.isNotEmpty,
            ))
        .toList();
  }

  /// Bloco 9 - Atividade recente (trilha de auditoria).
  List<({String descricao, String quando, Color cor})> _atividade(DadosDashboard d) {
    final ordenados = [...d.logs]..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return ordenados
        .take(kLimiteLista)
        .map((log) => (
              descricao: log.descricao,
              quando: Formato.dataHora(log.dataHora),
              cor: corDoLog(log.acao),
            ))
        .toList();
  }
}
