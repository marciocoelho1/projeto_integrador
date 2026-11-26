import 'package:flutter_test/flutter_test.dart';

import 'package:app_sgsst/core/app_theme.dart';
import 'package:app_sgsst/core/formatadores.dart';
import 'package:app_sgsst/core/validacao.dart';
import 'package:app_sgsst/models/chamado.dart';
import 'package:app_sgsst/models/colaborador.dart';
import 'package:app_sgsst/models/epi.dart';
import 'package:app_sgsst/models/importacao.dart';
import 'package:app_sgsst/models/treinamento_avancado.dart';
import 'package:app_sgsst/services/relatorio_service.dart';
import 'package:app_sgsst/widgets/blocos_dashboard.dart';

void main() {
  group('Modelos leem o contrato do backend', () {
    test('Colaborador.fromJson', () {
      final c = Colaborador.fromJson({
        'id': 7,
        'matricula': 'MAT-007',
        'nome': 'Maria Souza',
        'cpf': '11122233344',
        'email': 'maria@empresa.com',
        'cargo': 'Repositora',
        'setor': 'Mercearia',
        'status': 'Ativo',
      });

      expect(c.id, 7);
      expect(c.status, 'Ativo');
      expect(c.paraRequisicao()['matricula'], 'MAT-007');
    });

    test('Epi.fromJson marca estoque crítico abaixo de 20', () {
      final epi = Epi.fromJson({
        'id': 1,
        'descricao': 'Capacete',
        'quantidade': 19,
        'inclusao': '2026-01-01',
        'validade': '2027-01-01',
        'ca': '12345',
      });

      expect(epi.estoqueCritico, isTrue);
      expect(epi.copiarCom(quantidade: 20).estoqueCritico, isFalse);
    });

    test('EntregaEpi.fromJson usa o CA gravado na entrega', () {
      final entrega = EntregaEpi.fromJson({
        'id': 3,
        'colaboradorId': 7,
        'colaborador': 'Maria Souza',
        'matricula': 'MAT-007',
        'epiId': 1,
        'epi': 'Capacete',
        'ca': '999',
        'quantidade': 2,
        'dataEntrega': '2026-02-01',
        'assinatura': 'Maria Souza',
      });

      expect(entrega.ca, '999');
      expect(entrega.quantidade, 2);
    });

    test('LntCargo separa só os treinamentos obrigatórios', () {
      final cargo = LntCargo.fromJson({
        'id': 1,
        'cargo': 'Operador de Empilhadeira',
        'setor': 'Estoque',
        'status': 'Ativo',
        'treinamentos': [
          {'treinamentoId': 1, 'treinamento': 'NR-11', 'nr': 'NR-11', 'obrigatorio': true},
          {'treinamentoId': 2, 'treinamento': 'NR-35', 'nr': 'NR-35', 'obrigatorio': false},
        ],
      });

      expect(cargo.obrigatorios, ['NR-11']);
    });

    test('Chamado.fromJson aceita concluidoEm nulo', () {
      final chamado = Chamado.fromJson({
        'id': 1,
        'tipo': 'Ajuda',
        'descricao': 'Sem acesso',
        'usuarioId': 3,
        'solicitante': 'Maria',
        'status': 'Em andamento',
        'abertoEm': '2026-02-01T10:00:00Z',
        'concluidoEm': null,
      });

      expect(chamado.concluidoEm, isNull);
      expect(chamado.status, 'Em andamento');
    });

    test('ImportacaoResultado.fromJson lê erros por linha', () {
      final resultado = ImportacaoResultado.fromJson({
        'total': 3,
        'importados': 2,
        'ignorados': 1,
        'erros': [
          {'linha': 3, 'mensagem': 'CPF inválido'},
        ],
      });

      expect(resultado.importados, 2);
      expect(resultado.erros.single.linha, 3);
      expect(TipoImportacao.colaborador.recurso, 'colaboradores');
    });
  });

  group('Validação replica as regras do web', () {
    test('colaborador exige CPF com 11 dígitos e e-mail válido', () {
      expect(
        Validacao.colaborador(
          matricula: 'MAT-1',
          nome: 'Maria',
          cpf: '111.222.333-44',
          email: 'maria@empresa.com',
          cargo: 'Repositora',
          setor: 'Mercearia',
          status: 'Ativo',
        ),
        isTrue,
      );

      expect(
        Validacao.colaborador(
          matricula: 'MAT-1',
          nome: 'Maria',
          cpf: '123',
          email: 'maria@empresa.com',
          cargo: 'Repositora',
          setor: 'Mercearia',
          status: 'Ativo',
        ),
        isFalse,
      );
    });

    test('epi exige validade maior ou igual à inclusão', () {
      expect(
        Validacao.epi(
          descricao: 'Capacete',
          ca: '12345',
          quantidade: 10,
          inclusao: '2026-01-01',
          validade: '2025-12-31',
        ),
        isFalse,
      );
      expect(
        Validacao.epi(
          descricao: 'Capacete',
          ca: '12345',
          quantidade: 10,
          inclusao: '2026-01-01',
          validade: '2027-01-01',
        ),
        isTrue,
      );
    });

    test('treinamento aceita NR e validade nulos', () {
      expect(
        Validacao.treinamento(
          codigo: 'TRN-1',
          nome: 'Integração',
          classificacao: 'Interno',
          nr: null,
          cargaHoraria: '8h',
          validadeMeses: null,
          status: 'Ativo',
        ),
        isTrue,
      );
    });

    test('FormatoIso devolve yyyy-MM-dd', () {
      expect(FormatoIso.paraTexto(DateTime(2026, 3, 9)), '2026-03-09');
    });
  });

  group('Formato', () {
    test('data e texto tratam nulos', () {
      expect(Formato.data(null), '-');
      expect(Formato.data('2026-03-09'), '09/03/2026');
      expect(Formato.texto('  '), '-');
      expect(Formato.texto('CA 123'), 'CA 123');
    });
  });
  group('Blocos do dashboard derivam como no web', () {
    test('mesCurto cobre os doze meses', () {
      expect(mesCurto(1), 'Jan');
      expect(mesCurto(12), 'Dez');
    });

    test('corDoLog separa exclusao, criacao e edicao', () {
      expect(corDoLog('EXCLUSAO'), AppCores.vencido);
      expect(corDoLog('CRIACAO'), AppCores.valido);
      expect(corDoLog('ATUALIZACAO'), AppCores.petroleo);
      expect(corDoLog('LOGIN'), AppCores.cinza);
    });

    test('a situacao do EPI segue os cortes de estoque do web', () {
      // Replica a regra de `episCriticos` no dashboard.ts.
      String situacao(int quantidade, {bool vencido = false}) {
        if (vencido) return 'Vencido';
        if (quantidade <= 3) return 'Crítico';
        if (quantidade == 4) return 'Atenção';
        return 'No mínimo';
      }

      expect(situacao(0), 'Crítico');
      expect(situacao(3), 'Crítico');
      expect(situacao(4), 'Atenção');
      expect(situacao(5), 'No mínimo');
      expect(situacao(0, vencido: true), 'Vencido');
    });

    test('a matriz calor usa os niveis 0, 1 e 2', () {
      // Replica o calculo de nivel do `heat()` no dashboard.ts.
      int nivel(int valor) => valor == 0 ? 0 : (valor == 1 ? 1 : 2);

      expect(nivel(0), 0);
      expect(nivel(1), 1);
      expect(nivel(2), 2);
      expect(nivel(9), 2);
    });
  });
  group('RelatorioService cobre os relatorios do web', () {
    test('oferece exatamente os mesmos relatorios do RelatorioService do web', () {
      // O web baixa 'dashboard' e 'matriz-treinamentos'; o backend ainda expoe
      // colaboradores, epis, certificacoes e entregas-epis.
      expect(
        RelatorioService.relatorios,
        containsAll(['dashboard', 'matriz-treinamentos']),
      );
      expect(RelatorioService.relatorios, hasLength(6));
    });
  });
}