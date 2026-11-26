import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/colaborador.dart';
import '../models/configuracao.dart';
import '../models/dashboard_dados.dart';
import '../models/epi.dart';
import '../models/indicador.dart';
import '../models/treinamento.dart';
import '../models/treinamento_avancado.dart';
import 'auditoria_service.dart';
import 'auth_service.dart';
import 'colaborador_service.dart';
import 'controle_servidor_frio.dart';
import 'epi_service.dart';
import 'relatorio_service.dart';
import 'treinamento_avancado_service.dart';
import 'treinamento_service.dart';

class DashboardService {
  final AuthService _auth;
  DashboardService(this._auth);

  /// Carrega as sete fontes em paralelo, como o `forkJoin` do web. Uma falha em
  /// qualquer uma delas deixa a tela inteira em erro, em vez de mostrar metade dos
  /// numeros de um momento e metade de outro.
  Future<DadosDashboard> carregar() async {
    final resultados = await Future.wait([
      _indicadores(),
      ColaboradorService(_auth).listar(),
      EpiService(_auth).obterEpis(),
      EpiService(_auth).obterEntregas(),
      TreinamentoAvancadoService(_auth).listarVinculos(),
      TreinamentoService(_auth).listar(),
      AuditoriaService(_auth).listar(),
    ]);

    return DadosDashboard(
      indicadores: resultados[0] as Indicadores,
      colaboradores: resultados[1] as List<Colaborador>,
      epis: resultados[2] as List<Epi>,
      entregas: resultados[3] as List<EntregaEpi>,
      vinculos: resultados[4] as List<VinculoTreinamento>,
      treinamentos: resultados[5] as List<Treinamento>,
      logs: resultados[6] as List<LogAuditoria>,
    );
  }

  Future<Indicadores> _indicadores() async {
    final resposta = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/dashboard/indicadores'),
          headers: _auth.cabecalhoAuth,
        )
        .timeout(ControleServidorFrio.instancia.prazo)
        .whenComplete(ControleServidorFrio.instancia.aquecer);

    if (resposta.statusCode == 401) {
      throw AuthException('Sessão expirada. Entre novamente.');
    }
    if (resposta.statusCode != 200) {
      throw Exception('Falha ao carregar indicadores (${resposta.statusCode}).');
    }

    final json = jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
    return Indicadores.fromJson(json);
  }

  /// Baixa o CSV do dashboard. Delegado ao RelatorioService, que agora atende
  /// tambem a matriz de treinamentos (mesmo endpoint e mesmo tratamento de erro).
  Future<String> baixarRelatorioCsv(String relatorio) =>
      RelatorioService(_auth).baixar(relatorio);
}
