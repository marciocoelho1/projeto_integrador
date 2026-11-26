import 'colaborador.dart';
import 'configuracao.dart';
import 'epi.dart';
import 'indicador.dart';
import 'treinamento.dart';
import 'treinamento_avancado.dart';

/// Tudo que o dashboard precisa para montar os dois níveis da tela, espelhando
/// `DadosDashboard` do web: os indicadores agregados no servidor e as listas que o
/// servidor ainda nao agrega (setores, vinculos por NR, estoque critico, entregas,
/// chamados e trilha de auditoria).
///
/// O backend expoe cada lista como recurso REST; a tela combina no cliente em vez
/// de exigir um endpoint novo, exatamente como o web faz.
class DadosDashboard {
  final Indicadores indicadores;
  final List<Colaborador> colaboradores;
  final List<Epi> epis;
  final List<EntregaEpi> entregas;
  final List<VinculoTreinamento> vinculos;
  final List<Treinamento> treinamentos;
  final List<LogAuditoria> logs;

  const DadosDashboard({
    required this.indicadores,
    required this.colaboradores,
    required this.epis,
    required this.entregas,
    required this.vinculos,
    required this.treinamentos,
    required this.logs,
  });
}
