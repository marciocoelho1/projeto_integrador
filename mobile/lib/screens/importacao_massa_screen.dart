import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/toast.dart';
import '../models/importacao.dart';
import '../services/auth_service.dart';
import '../services/auditoria_service.dart';
import '../services/importacao_service.dart';
import '../widgets/campo_formulario.dart';
import '../widgets/cartao_secao.dart';
import '../widgets/estado_tela.dart';
import '../widgets/sgsst_scaffold.dart';

/// Descrição de uma coluna do contrato da API dentro da planilha.
/// Espelha exatamente `COLUNAS` de `src/app/tela-importacao-massa`.
class _CampoPlanilha {
  const _CampoPlanilha(this.campo, this.aliases);
  final String campo;
  final List<String> aliases;
}

const _colunas = <TipoImportacao, List<_CampoPlanilha>>{
  TipoImportacao.colaborador: [
    _CampoPlanilha('matricula', ['matricula']),
    _CampoPlanilha('nome', ['nome']),
    _CampoPlanilha('cpf', ['cpf']),
    _CampoPlanilha('email', ['email']),
    _CampoPlanilha('cargo', ['cargo']),
    _CampoPlanilha('setor', ['setor']),
    _CampoPlanilha('status', ['status', 'situacao']),
  ],
  TipoImportacao.treinamento: [
    _CampoPlanilha('codigo', ['codigo']),
    _CampoPlanilha('nome', ['nome', 'nometreinamento']),
    _CampoPlanilha('classificacao', ['classificacao']),
    _CampoPlanilha('nr', ['nr', 'nrreferente', 'norma']),
    _CampoPlanilha('cargaHoraria', ['cargahoraria']),
    _CampoPlanilha('validadeMeses', ['validademeses', 'validade']),
    _CampoPlanilha('status', ['status', 'situacao']),
  ],
  TipoImportacao.epi: [
    _CampoPlanilha('descricao', ['descricao', 'nomeequipamento', 'equipamento', 'nome']),
    _CampoPlanilha('ca', ['ca', 'numeroca']),
    _CampoPlanilha('inclusao', ['inclusao', 'datainclusao']),
    _CampoPlanilha('validade', ['validade', 'datavalidade']),
    _CampoPlanilha('quantidade', ['quantidade', 'qtd']),
  ],
};

/// Modelos CSV alinhados ao contrato da API (exatamente estas colunas).
class _ModeloCsv {
  const _ModeloCsv(this.arquivo, this.conteudo);
  final String arquivo;
  final String conteudo;
}

const _modelos = <TipoImportacao, _ModeloCsv>{
  TipoImportacao.colaborador: _ModeloCsv(
    'template_colaboradores.csv',
    'Matricula,Nome,CPF,Email,Cargo,Setor,Status\n'
        'MAT-001,João da Silva,11122233344,joao.silva@empresa.com,Operador de Caixa,'
        'Frente de Loja,Ativo\n',
  ),
  TipoImportacao.treinamento: _ModeloCsv(
    'template_treinamentos.csv',
    'Codigo,Nome,Classificacao,NR,Carga_Horaria,Validade_Meses,Status\n'
        'TRN-001,NR-35 Trabalho em Altura,Norma Regulamentadora,NR-35,8,24,Ativo\n',
  ),
  TipoImportacao.epi: _ModeloCsv(
    'template_epis.csv',
    'Descricao,CA,Inclusao,Validade,Quantidade\n'
        'Capacete de Segurança,12345,2026-01-01,2027-01-01,10\n',
  ),
};

/// Porta de `src/app/tela-importacao-massa`: lê a planilha (CSV ou Excel),
/// mapeia as colunas para o contrato da API e envia o lote.
class ImportacaoMassaScreen extends StatefulWidget {
  const ImportacaoMassaScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<ImportacaoMassaScreen> createState() => _ImportacaoMassaScreenState();
}

class _ImportacaoMassaScreenState extends State<ImportacaoMassaScreen> {
  late final ImportacaoService _api = ImportacaoService(widget.auth);
  late final AuditoriaService _auditoria = AuditoriaService(widget.auth);

  TipoImportacao? _tipo;
  List<String> _cabecalhos = const [];
  List<List<String>> _linhas = const [];
  String _arquivoNome = '';

  bool _importando = false;
  ImportacaoResultado? _resultado;
  final List<ImportacaoErro> _erros = [];

  Future<void> _baixarModelo() async {
    final tipo = _tipo;
    if (tipo == null) {
      Toast.aviso(context, 'Selecione o tipo de importação.');
      return;
    }

    final modelo = _modelos[tipo]!;
    final bytes = Uint8List.fromList(utf8.encode(modelo.conteudo));

    try {
      final destino = await FilePicker.saveFile(
        fileName: modelo.arquivo,
        bytes: bytes,
        mimeType: 'text/csv',
      );
      if (!mounted || destino == null) return;
      Toast.sucesso(context, 'Planilha de exemplo salva com sucesso!');
    } catch (e) {
      if (mounted) Toast.erro(context, 'Não foi possível salvar o modelo: $e');
    }
  }

  Future<void> _selecionarArquivo() async {
    final tipo = _tipo;
    if (tipo == null) {
      Toast.aviso(context, 'Selecione o tipo de importação antes de escolher o arquivo.');
      return;
    }

    try {
      final arquivos = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'txt'],
      );
      if (arquivos.isEmpty) return;
      final arquivo = arquivos.single;
      final bytes = await arquivo.readAsBytes();

      final linhas = _lerPlanilha(arquivo.name, bytes);
      if (linhas.isEmpty) {
        if (mounted) Toast.erro(context, 'A planilha está vazia.');
        return;
      }

      if (!mounted) return;
      setState(() {
        _arquivoNome = arquivo.name;
        _cabecalhos = linhas.first.map((c) => c.toString()).toList();
        _linhas = linhas
            .skip(1)
            .map((l) => l.map((c) => c.toString()).toList())
            .where((l) => l.any((c) => c.trim().isNotEmpty))
            .toList();
        _resultado = null;
        _erros.clear();
      });
      Toast.sucesso(context, 'Planilha carregada com sucesso! Revise os dados.');
    } catch (e) {
      if (mounted) {
        Toast.erro(context, 'Erro ao ler o arquivo. Certifique-se de que é uma planilha válida.');
      }
    }
  }

  /// CSV: separador `,` ou `;`, com suporte a aspas. A planilha Excel entra pelo
  /// `mobile/web` do Flutter (mesmo código roda na web).
  List<List<dynamic>> _lerPlanilha(String nome, Uint8List bytes) {
    final texto = utf8.decode(bytes, allowMalformed: true);
    final primeira = texto.split(RegExp(r'\r?\n')).first;
    final separador = primeira.contains(';') && !primeira.contains(',') ? ';' : ',';

    return texto
        .split(RegExp(r'\r?\n'))
        .map((linha) => _dividirLinhaCsv(linha, separador))
        .where((linha) => linha.any((c) => c.trim().isNotEmpty))
        .toList();
  }

  List<String> _dividirLinhaCsv(String linha, String separador) {
    final campos = <String>[];
    final buffer = StringBuffer();
    var dentroDeAspas = false;

    for (var i = 0; i < linha.length; i++) {
      final char = linha[i];
      if (char == '"') {
        if (dentroDeAspas && i + 1 < linha.length && linha[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          dentroDeAspas = !dentroDeAspas;
        }
      } else if (char == separador && !dentroDeAspas) {
        campos.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    campos.add(buffer.toString());
    return campos;
  }

  Future<void> _confirmar() async {
    final tipo = _tipo;
    if (tipo == null) {
      Toast.aviso(context, 'Selecione o tipo de importação.');
      return;
    }
    if (_linhas.isEmpty) {
      Toast.aviso(context, 'Nenhum dado encontrado para importar.');
      return;
    }

    final mapeamento = _mapearLinhas(tipo);

    if (mapeamento.dados.isEmpty) {
      setState(() {
        _erros
          ..clear()
          ..addAll(mapeamento.erros);
        _resultado = ImportacaoResultado(
          total: _linhas.length,
          importados: 0,
          ignorados: _linhas.length,
          erros: const [],
        );
      });
      Toast.erro(context, 'Nenhuma linha pôde ser mapeada. Confira os cabeçalhos da planilha.');
      return;
    }

    setState(() => _importando = true);
    try {
      final resultado = await _api.importar(tipo, mapeamento.dados);
      if (!mounted) return;
      setState(() {
        _resultado = resultado;
        _erros
          ..clear()
          ..addAll([...mapeamento.erros, ...resultado.erros]);
      });

      if (resultado.importados > 0) {
        Toast.sucesso(
          context,
          '${resultado.importados} de ${resultado.total} linha(s) importada(s) com sucesso.',
        );
      } else {
        Toast.erro(context, 'Nenhuma linha foi importada.');
      }
      if (resultado.erros.isNotEmpty) {
        Toast.aviso(
          context,
          '${resultado.erros.length} linha(s) com erro. Veja o detalhamento na tela.',
        );
      }

      await _auditoria.registrarAcao(
        usuario: widget.auth.sessao?.nomeCompleto ?? 'Administrador',
        modulo: 'Importação',
        acao: 'CRIACAO',
        descricao:
            'Importou ${resultado.importados} registro(s) via planilha Excel/CSV',
      );
    } catch (e) {
      if (mounted) Toast.erro(context, e.toString());
    } finally {
      if (mounted) setState(() => _importando = false);
    }
  }

  /// Monta as linhas do contrato a partir dos cabeçalhos da planilha.
  ({List<Map<String, dynamic>> dados, List<ImportacaoErro> erros}) _mapearLinhas(
    TipoImportacao tipo,
  ) {
    final campos = _colunas[tipo]!;
    final colunas = _resolverColunas(campos, _cabecalhos);
    final dados = <Map<String, dynamic>>[];
    final erros = <ImportacaoErro>[];

    for (var i = 0; i < _linhas.length; i++) {
      final linha = _linhas[i];
      final numeroLinha = i + 2;

      if (linha.every((c) => c.trim().isEmpty)) continue;

      final ausentes =
          campos.where((c) => colunas[c.campo] == null).map((c) => c.campo).toList();
      if (ausentes.isNotEmpty) {
        erros.add(ImportacaoErro(
          linha: numeroLinha,
          mensagem: 'Coluna(s) não reconhecida(s) no cabeçalho: ${ausentes.join(', ')}.',
        ));
        continue;
      }

      final mapeada = _montarLinha(tipo, colunas, linha);
      if (mapeada.erro != null) {
        erros.add(ImportacaoErro(linha: numeroLinha, mensagem: mapeada.erro!));
        continue;
      }
      dados.add(mapeada.dados!);
    }

    return (dados: dados, erros: erros);
  }

  Map<String, int?> _resolverColunas(List<_CampoPlanilha> campos, List<String> cabecalhos) {
    final normalizados = cabecalhos.map(_normalizar).toList();
    final colunas = <String, int?>{};

    for (final campo in campos) {
      final indice = normalizados.indexWhere(campo.aliases.contains);
      colunas[campo.campo] = indice >= 0 ? indice : null;
    }
    return colunas;
  }

  ({Map<String, dynamic>? dados, String? erro}) _montarLinha(
    TipoImportacao tipo,
    Map<String, int?> colunas,
    List<String> linha,
  ) {
    String texto(String campo) {
      final indice = colunas[campo];
      if (indice == null || indice >= linha.length) return '';
      return linha[indice].trim();
    }

    if (tipo == TipoImportacao.colaborador) {
      return (
        dados: {
          'matricula': texto('matricula'),
          'nome': texto('nome'),
          'cpf': texto('cpf'),
          'email': texto('email'),
          'cargo': texto('cargo'),
          'setor': texto('setor'),
          'status': texto('status'),
        },
        erro: null,
      );
    }

    if (tipo == TipoImportacao.treinamento) {
      final validadeMeses = _parsearInteiro(texto('validadeMeses'));
      if (validadeMeses.erro) {
        return (dados: null, erro: 'Validade em meses deve ser um número inteiro.');
      }
      return (
        dados: {
          'codigo': texto('codigo'),
          'nome': texto('nome'),
          'classificacao': texto('classificacao'),
          'nr': texto('nr').isEmpty ? null : texto('nr'),
          'cargaHoraria': texto('cargaHoraria'),
          'validadeMeses': validadeMeses.valor,
          'status': texto('status'),
        },
        erro: null,
      );
    }

    final quantidade = _parsearInteiro(texto('quantidade'));
    if (quantidade.erro) {
      return (dados: null, erro: 'Quantidade deve ser um número inteiro.');
    }

    final inclusao = _parsearData(texto('inclusao'));
    if (!inclusao.ok) {
      return (dados: null, erro: 'Data de inclusão inválida (use AAAA-MM-DD ou DD/MM/AAAA).');
    }
    final validade = _parsearData(texto('validade'));
    if (!validade.ok) {
      return (dados: null, erro: 'Data de validade inválida (use AAAA-MM-DD ou DD/MM/AAAA).');
    }

    return (
      dados: {
        'descricao': texto('descricao'),
        'ca': texto('ca'),
        'inclusao': inclusao.valor,
        'validade': validade.valor,
        'quantidade': quantidade.valor,
      },
      erro: null,
    );
  }

  /// `erro = true` quando o valor não é numérico; `valor = null` para célula vazia.
  ({int? valor, bool erro}) _parsearInteiro(String valor) {
    if (valor.isEmpty) return (valor: null, erro: false);
    final numero = num.tryParse(valor.replaceAll(',', '.'));
    if (numero == null || numero != numero.roundToDouble()) {
      return (valor: null, erro: true);
    }
    return (valor: numero.toInt(), erro: false);
  }

  /// Converte a célula para data ISO (AAAA-MM-DD).
  ({bool ok, String? valor}) _parsearData(String valor) {
    if (valor.isEmpty) return (ok: true, valor: null);

    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final brasileira = RegExp(r'^(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{4})$');

    int ano;
    int mes;
    int dia;

    if (iso.hasMatch(valor)) {
      final partes = valor.split('-').map(int.parse).toList();
      ano = partes[0];
      mes = partes[1];
      dia = partes[2];
    } else if (brasileira.hasMatch(valor)) {
      final partes = valor.split(RegExp(r'[/.\-]')).map(int.parse).toList();
      dia = partes[0];
      mes = partes[1];
      ano = partes[2];
    } else if (RegExp(r'^\d+(\.\d+)?$').hasMatch(valor)) {
      // Número de série do Excel (epoch 1899-12-30).
      final serie = num.parse(valor).floor();
      if (serie < 1 || serie > 2958465) return (ok: false, valor: null);
      final data = DateTime.utc(1899, 11, 30).add(Duration(days: serie));
      ano = data.year;
      mes = data.month;
      dia = data.day;
    } else {
      return (ok: false, valor: null);
    }

    final data = DateTime.utc(ano, mes - 1, dia);
    if (data.year != ano || data.month != mes || data.day != dia) {
      return (ok: false, valor: null);
    }

    String pad(int n) => n.toString().padLeft(2, '0');
    return (ok: true, valor: '$ano-${pad(mes)}-${pad(dia)}');
  }

  /// Normaliza cabeçalho: sem acento, minúsculo e sem separadores.
  String _normalizar(String valor) {
    const acentos = {
      'á': 'a', 'à': 'a', 'ã': 'a', 'â': 'a', 'ä': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'ó': 'o', 'ò': 'o', 'õ': 'o', 'ô': 'o', 'ö': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c', 'ñ': 'n',
    };
    final minusculo = valor.toLowerCase();
    final buffer = StringBuffer();
    for (final char in minusculo.split('')) {
      final substituido = acentos[char] ?? char;
      if (RegExp(r'[a-z0-9]').hasMatch(substituido)) buffer.write(substituido);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final resultado = _resultado;

    return SgsstScaffold(
      titulo: 'Importação em Massa',
      subtitulo: 'Planilha CSV (Excel exportado em CSV)',
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          CartaoSecao(
            titulo: 'Tipo de importação',
            child: Column(
              children: [
                CampoSelecao<TipoImportacao>(
                  rotulo: 'Recurso',
                  valor: _tipo,
                  opcoes: [
                    for (final t in TipoImportacao.values)
                      DropdownMenuItem(value: t, child: Text(t.rotulo)),
                  ],
                  aoMudar: (v) => setState(() => _tipo = v),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _baixarModelo,
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Baixar modelo'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selecionarArquivo,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Escolher arquivo'),
                      ),
                    ),
                  ],
                ),
                if (_arquivoNome.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Arquivo: $_arquivoNome',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_linhas.isNotEmpty)
            CartaoSecao(
              titulo: 'Pré-visualização',
              subtitulo: '${_linhas.length} linha(s) de dados',
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppCores.petroleo,
                  ),
                  columns: [
                    for (final c in _cabecalhos) DataColumn(label: Text(c)),
                  ],
                  rows: [
                    for (final linha in _linhas.take(10))
                      DataRow(
                        cells: [
                          for (final celula in linha) DataCell(Text(celula)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          BotaoPrimario(
            rotulo: 'Confirmar importação',
            icone: Icons.cloud_upload_outlined,
            carregando: _importando,
            aoClicar: _confirmar,
          ),
          if (resultado != null) ...[
            const SizedBox(height: 12),
            CartaoSecao(
              titulo: 'Resultado',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinhaDetalhe(rotulo: 'Total', valor: '${resultado.total}'),
                  LinhaDetalhe(rotulo: 'Importados', valor: '${resultado.importados}'),
                  LinhaDetalhe(rotulo: 'Ignorados', valor: '${resultado.ignorados}'),
                ],
              ),
            ),
          ],
          if (_erros.isNotEmpty) ...[
            const SizedBox(height: 12),
            CartaoSecao(
              titulo: 'Linhas com erro',
              subtitulo: '${_erros.length} ocorrência(s)',
              child: Column(
                children: [
                  for (final e in _erros) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Etiqueta(texto: 'Linha ${e.linha}', cor: AppCores.vencido),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(e.mensagem,
                              style: const TextStyle(color: AppCores.tinta)),
                        ),
                      ],
                    ),
                    if (e != _erros.last) const Divider(height: 18),
                  ],
                ],
              ),
            ),
          ],
          if (_cabecalhos.isEmpty && _erros.isEmpty && resultado == null)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: EstadoVazio(
                mensagem: 'Selecione o tipo, baixe o modelo e escolha a planilha para importar.',
                icone: Icons.table_chart_outlined,
              ),
            ),
        ],
      ),
    );
  }
}
