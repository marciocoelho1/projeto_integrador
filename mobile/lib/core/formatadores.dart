import 'package:intl/intl.dart';

/// Formatação de datas e números compartilhada pelas telas (padrão pt_BR).
class Formato {
  static final _data = DateFormat('dd/MM/yyyy');
  static final _dataHora = DateFormat('dd/MM/yyyy HH:mm');
  static final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  /// Converte o que a API devolve (ISO `yyyy-MM-dd` ou `yyyy-MM-ddTHH:mm:ss`) em data local.
  static DateTime? paraData(dynamic valor) {
    if (valor == null) return null;
    final texto = valor.toString().trim();
    if (texto.isEmpty) return null;
    return DateTime.tryParse(texto)?.toLocal();
  }

  static String data(dynamic valor) {
    final d = paraData(valor);
    return d == null ? '-' : _data.format(d);
  }

  static String dataHora(dynamic valor) {
    final d = paraData(valor);
    return d == null ? '-' : _dataHora.format(d);
  }

  /// Formato aceito pela API nos campos de data (`yyyy-MM-dd`).
  static String iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static String moeda(num valor) => _moeda.format(valor);

  static String texto(dynamic valor, {String vazio = '-'}) {
    if (valor == null) return vazio;
    final t = valor.toString().trim();
    return t.isEmpty ? vazio : t;
  }
}
