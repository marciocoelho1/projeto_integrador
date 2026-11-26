import 'package:flutter_test/flutter_test.dart';

import 'package:app_sgsst/models/sessao.dart';

void main() {
  Sessao sessaoCom(String grupo, List<String> modulos) => Sessao.fromJson({
        'token': 'abc',
        'expiraEm': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        'usuario': {
          'id': 1,
          'login': 'admin',
          'nomeCompleto': 'Administrador TST',
          'grupo': grupo,
          'modulos': modulos,
        },
      });

  test('Sessao lê módulos e nome do login', () {
    final s = sessaoCom('Administrador TST', ['sgst_dashboard', 'sgst_epis']);

    expect(s.nomeCompleto, 'Administrador TST');
    expect(s.modulos.length, 2);
    expect(s.expirada, isFalse);
  });

  test('Sessao expirada quando a data já passou', () {
    final s = Sessao.fromJson({
      'token': 'abc',
      'expiraEm': DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
      'usuario': {
        'id': 1,
        'login': 'admin',
        'nomeCompleto': 'Administrador',
        'grupo': 'Administrador TST',
        'modulos': <String>[],
      },
    });

    expect(s.expirada, isTrue);
  });
}
