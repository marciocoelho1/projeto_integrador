/// Porta de `src/app/service/crud-validation.ts`: mesmas regras de campos,
/// limites e formatos aceitos pelo backend.
class Validacao {
  static bool _texto(String? valor, int max, {bool opcional = false}) {
    if (valor == null || valor.trim().isEmpty) return opcional;
    return valor.length <= max;
  }

  static bool _inteiro(int? valor) =>
      valor != null && valor >= 0 && valor <= 2147483647;

  static bool _dataIso(String? valor) {
    if (valor == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(valor)) {
      return false;
    }
    final d = DateTime.tryParse(valor);
    return d != null && FormatoIso.paraTexto(d) == valor;
  }

  static bool colaborador({
    required String matricula,
    required String nome,
    required String cpf,
    required String email,
    required String cargo,
    required String setor,
    required String status,
  }) {
    return _texto(matricula, 30) &&
        _texto(nome, 150) &&
        _texto(cpf, 14) &&
        cpf.replaceAll(RegExp(r'\D'), '').length == 11 &&
        _texto(email, 180) &&
        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim()) &&
        _texto(cargo, 120) &&
        _texto(setor, 120) &&
        const ['Ativo', 'Inativo', 'Afastado'].contains(status);
  }

  static bool treinamento({
    required String codigo,
    required String nome,
    required String classificacao,
    required String? nr,
    required String cargaHoraria,
    required int? validadeMeses,
    required String status,
  }) {
    return _texto(codigo, 30) &&
        _texto(nome, 180) &&
        _texto(classificacao, 60) &&
        _texto(nr, 60, opcional: true) &&
        _texto(cargaHoraria, 30) &&
        (validadeMeses == null || _inteiro(validadeMeses)) &&
        const ['Ativo', 'Inativo'].contains(status);
  }

  static bool epi({
    required String descricao,
    required String ca,
    required int? quantidade,
    required String? inclusao,
    required String? validade,
  }) {
    return _texto(descricao, 180) &&
        _texto(ca, 30) &&
        _inteiro(quantidade) &&
        _dataIso(inclusao) &&
        _dataIso(validade) &&
        validade!.compareTo(inclusao!) >= 0;
  }
}

/// Comparação e formatação de datas no formato do backend, sem depender do intl.
class FormatoIso {
  static String paraTexto(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
