import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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

/// Salva um CSV que veio do servidor e devolve o caminho escolhido.
///
/// O web dispara o download pelo navegador (`RelatorioService.salvar`); no
/// celular o equivalente e o seletor de arquivos do sistema. O BOM UTF-8 e
/// preservado porque o Excel pt-BR sem ele le os acentos errado.
Future<String> salvarCsv(String conteudo, String nomeArquivo) async {
  final bytes = Uint8List.fromList(<int>[0xEF, 0xBB, 0xBF, ...utf8.encode(conteudo)]);

  final caminho = await FilePicker.saveFile(
    dialogTitle: 'Salvar $nomeArquivo',
    fileName: nomeArquivo,
    bytes: bytes,
    mimeType: 'text/csv',
  );

  if (caminho == null) return nomeArquivo;
  // No desktop o FilePicker devolve uma Uri; gravar o conteudo e nosso.
  if (!Platform.isAndroid && !Platform.isIOS) {
    await File.fromUri(caminho).writeAsBytes(bytes);
  }
  return caminho.toString();
}
