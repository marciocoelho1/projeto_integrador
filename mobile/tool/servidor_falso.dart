import 'dart:convert';
import 'dart:io';

/// Servidor de mentira que devolve o contrato real da API para validar as telas
/// em execução sem precisar do backend e do banco.
Future<void> main() async {
  // 0.0.0.0 permite que o emulador Android alcance o host por 10.0.2.2.
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8099);
  stdout.writeln('Servidor falso em http://0.0.0.0:8099');

  String corpoLogin = '';

  dynamic corpo(String caminho, String metodo) {
    if (caminho.contains('/auth/login')) {
      final colaborador = corpoLogin.contains('colaborador');
      return {
        'token': 'fake',
        'expiraEm': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        'usuario': {
          'id': colaborador ? 2 : 1,
          'login': colaborador ? 'MAT-001' : 'admin',
          'nomeCompleto': colaborador ? 'Maria Souza' : 'Administrador TST',
          'grupo': colaborador ? 'Colaborador' : 'Administrador TST',
          'modulos': ['sgst_dashboard'],
        },
      };
    }
    if (caminho.contains('/dashboard/indicadores')) {
      return {
        'colaboradores': {'total': 3, 'ativos': 2, 'inativos': 0, 'afastados': 1},
        'certificacoes': {'total': 2, 'ativas': 1, 'vencidas': 1, 'vencendoEm30Dias': 1},
        'epis': {
          'emEstoque': 40,
          'proximoVencimento': 2,
          'vencidos': 1,
          'entreguesUltimos30Dias': 5,
          'totalTipos': 3,
        },
        'treinamentos': {
          'concluidos': 1,
          'pendentes': 1,
          'vencidos': 1,
          'total': 3,
          'porcentagem': 33,
        },
        'alertas': [
          {'tipo': 'EPI', 'mensagem': 'Estoque critico', 'criticidade': 'alta'},
        ],
        'geradoEm': DateTime.now().toIso8601String(),
      };
    }
    if (caminho.contains('/colaboradores')) {
      return [
        {
          'id': 1,
          'matricula': 'MAT-001',
          'nome': 'Maria Souza',
          'cpf': '11122233344',
          'email': 'maria@empresa.com',
          'cargo': 'Repositora',
          'setor': 'Mercearia',
          'status': 'Ativo',
        },
      ];
    }
    if (caminho.contains('/epis')) {
      return [
        {
          'id': 1,
          'descricao': 'Capacete',
          'quantidade': 12,
          'inclusao': '2026-01-01',
          'validade': '2027-01-01',
          'ca': '12345',
        },
      ];
    }
    if (caminho.contains('/entregas-epis')) {
      return [
        {
          'id': 9,
          'colaboradorId': 1,
          'colaborador': 'Maria Souza',
          'matricula': 'MAT-001',
          'epiId': 1,
          'epi': 'Capacete',
          'ca': '12345',
          'quantidade': 1,
          'dataEntrega': '2026-02-01',
          'assinatura': 'Maria Souza',
        },
      ];
    }
    if (caminho.contains('/treinamentos')) {
      return [
        {
          'id': 1,
          'codigo': 'TRN-001',
          'nome': 'NR-35 Trabalho em Altura',
          'classificacao': 'Norma',
          'nr': 'NR-35',
          'cargaHoraria': '8',
          'validadeMeses': 24,
          'status': 'Ativo',
        },
      ];
    }
    if (caminho.contains('/vinculos')) {
      return [
        {
          'id': 1,
          'colaboradorId': 1,
          'colaborador': 'Maria Souza',
          'cargo': 'Repositora',
          'treinamentoId': 1,
          'treinamento': 'NR-35',
          'dataConclusao': '2026-01-10',
          'status': 'Concluído',
          'validade': '2027-01-10',
        },
      ];
    }
    if (caminho.contains('/lnt/colaboradores')) {
      return [
        {
          'colaboradorId': 1,
          'colaborador': 'Maria Souza',
          'cargo': 'Repositora',
          'setor': 'Mercearia',
          'treinamentosPendentes': <String>[],
          'status': 'Conforme',
        },
      ];
    }
    if (caminho.contains('/lnt')) {
      return [
        {
          'id': 1,
          'cargo': 'Repositora',
          'setor': 'Mercearia',
          'status': 'Ativo',
          'treinamentos': [
            {'id': 1, 'treinamentoId': 1, 'treinamento': 'NR-35', 'nr': 'NR-35', 'obrigatorio': true},
          ],
        },
      ];
    }
    if (caminho.contains('/certificacoes')) {
      return [
        {
          'id': 1,
          'colaboradorId': 1,
          'colaborador': 'Maria Souza',
          'cargo': 'Repositora',
          'treinamentoId': 1,
          'treinamento': 'NR-35',
          'instituicao': 'SENAC',
          'cargaHoraria': '8h',
          'emitidaEm': '2026-01-10',
          'validade': '2027-01-10',
          'arquivoUrl': null,
          'status': 'Ativa',
        },
      ];
    }
    if (caminho.contains('/turmas-reciclagem')) {
      return [
        {
          'id': 1,
          'treinamentoId': 1,
          'treinamento': 'NR-35',
          'instrutor': 'Carlos',
          'dataAgendada': '2026-12-01',
          'vagas': 10,
          'status': 'Agendada',
        },
      ];
    }
    if (caminho.contains('/reciclagens')) {
      return [
        {
          'colaboradorId': 1,
          'colaborador': 'Maria Souza',
          'cargo': 'Repositora',
          'treinamentoId': 1,
          'treinamento': 'NR-35',
          'prazoMaximo': '2026-12-15',
          'diasRestantes': 12,
          'status': 'Pendente',
        },
      ];
    }
    if (caminho.contains('/chamados')) {
      return [
        {
          'id': 1,
          'tipo': 'Ajuda',
          'descricao': 'Sem acesso ao sistema',
          'usuarioId': 1,
          'solicitante': 'Maria Souza',
          'status': 'Em andamento',
          'abertoEm': DateTime.now().toIso8601String(),
          'concluidoEm': null,
        },
      ];
    }
    if (caminho.contains('/usuarios')) {
      return [
        {
          'id': 1,
          'nomeCompleto': 'Administrador TST',
          'login': 'admin',
          'email': 'admin@empresa.com',
          'cpf': '00000000001',
          'grupoId': 1,
          'grupo': 'Administrador TST',
          'status': 'Ativo',
          'modulos': ['sgst_dashboard'],
          'criadoEm': DateTime.now().toIso8601String(),
        },
      ];
    }
    if (caminho.contains('/grupos')) {
      return [
        {
          'id': 1,
          'nomenclatura': 'Administrador TST',
          'finalidade': 'Acesso irrestrito.',
          'modulos': ['sgst_dashboard'],
        },
      ];
    }
    if (caminho.contains('/modulos')) {
      return [
        {'chave': 'sgst_dashboard', 'titulo': 'Dashboard', 'detalhe': 'Indicadores'},
      ];
    }
    if (caminho.contains('/regras-alerta')) {
      return [
        {
          'codigo': 'EPI_VENCIDO',
          'nomeRegra': 'EPI vencido',
          'descricaoRegra': 'Alerta de EPI vencido',
          'ativa': true,
        },
      ];
    }
    if (caminho.contains('/parametros')) {
      return [
        {'chave': 'dias_alerta', 'valor': '60', 'descricao': 'Dias de alerta'},
      ];
    }
    if (caminho.contains('/auditoria')) {
      return [
        {
          'id': 1,
          'dataHora': DateTime.now().toIso8601String(),
          'usuarioId': 1,
          'usuario': 'Administrador TST',
          'modulo': 'Importação',
          'acao': 'CRIACAO',
          'descricao': 'Importou 3 registros',
          'metodo': 'POST',
          'caminho': '/api/importacao',
          'statusHttp': 200,
        },
      ];
    }
    if (caminho.contains('/importacao')) {
      return {'total': 1, 'importados': 1, 'ignorados': 0, 'erros': <dynamic>[]};
    }
    return <dynamic>[];
  }

  await for (final req in server) {
    // Log de cada requisicao: e como se prova, rodando o app, quais telas de fato
    // buscaram dados na API.
    stdout.writeln('${req.method} ${req.uri}');
    // CORS liberado para o app web (flutter build web / flutter run -d chrome).
    req.response.headers.set('Access-Control-Allow-Origin', '*');
    req.response.headers.set('Access-Control-Allow-Headers', '*');
    req.response.headers.set('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS');
    if (req.method == 'OPTIONS') {
      req.response.statusCode = 204;
      await req.response.close();
      continue;
    }
    req.response.headers.set('Content-Type', 'application/json; charset=utf-8');
    if (req.uri.path.endsWith('/auth/login')) {
      corpoLogin = await utf8.decoder.bind(req).join();
    }
    req.response.write(jsonEncode(corpo(req.uri.path, req.method)));
    await req.response.close();
  }
}
