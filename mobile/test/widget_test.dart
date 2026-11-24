import 'package:flutter_test/flutter_test.dart';
import 'package:app_sgsst/config/api_config.dart';
import 'package:app_sgsst/models/indicador.dart';

void main() {
  test('ApiConfig devolve uma URL com esquema http', () {
    expect(ApiConfig.baseUrl, startsWith('http'));
  });

  test('Indicadores.fromJson le o contrato do backend', () {
    final json = {
      'colaboradores': {'total': 10, 'ativos': 8, 'inativos': 1, 'afastados': 1},
      'certificacoes': {'total': 5, 'ativas': 4, 'vencidas': 1, 'vencendoEm30Dias': 2},
      'epis': {
        'emEstoque': 50,
        'proximoVencimento': 3,
        'vencidos': 2,
        'entreguesUltimos30Dias': 7,
        'totalTipos': 4,
      },
      'treinamentos': {
        'concluidos': 6,
        'pendentes': 4,
        'vencidos': 1,
        'total': 10,
        'porcentagem': 50,
      },
      'alertas': [
        {'tipo': 'EPI', 'mensagem': 'Estoque critico', 'criticidade': 'alta'},
      ],
      'geradoEm': '2026-11-23T20:00:00-03:00',
    };

    final d = Indicadores.fromJson(json);

    expect(d.colaboradores.ativos, 8);
    expect(d.treinamentos.porcentagem, 50);
    expect(d.epis.totalTipos, 4);
    expect(d.alertas.single.tipo, 'EPI');
    expect(d.alertas.single.criticidade, 'alta');
  });
}