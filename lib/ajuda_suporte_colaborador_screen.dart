import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Tela Ajuda e Suporte da Área do Colaborador.
///
/// O colaborador visualiza apenas os próprios chamados:
/// GET /chamados?meus=true
///
/// Ao enviar:
/// POST /chamados
/// Body: { "tipo": "Ajuda" | "Erro", "descricao": "..." }
class AjudaSuporteColaboradorScreen extends StatefulWidget {
  const AjudaSuporteColaboradorScreen({
    super.key,
    this.apiBaseUrl = 'http://localhost:3000/api',
    this.httpClient,
  });

  final String apiBaseUrl;
  final http.Client? httpClient;

  @override
  State<AjudaSuporteColaboradorScreen> createState() =>
      _AjudaSuporteColaboradorScreenState();
}

class _AjudaSuporteColaboradorScreenState
    extends State<AjudaSuporteColaboradorScreen> {
  static const Color _background = Color(0xFFF3F4F6);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF4B5563);
  static const Color _border = Color(0xFFD1D5DB);

  final _descriptionController = TextEditingController();
  final _internalClient = http.Client();

  String _ticketType = 'Solicitar Ajuda';
  final List<_SupportRequest> _requests = [];
  bool _loading = false;
  bool _sending = false;
  String? _error;

  http.Client get _http => widget.httpClient ?? _internalClient;

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    final base = widget.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
    return Uri.parse('$base$path').replace(queryParameters: queryParameters);
  }

  Map<String, String> get _headers => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _internalClient.close();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _http.get(
        _uri('/chamados', queryParameters: const {'meus': 'true'}),
        headers: _headers,
      );
      _checkResponse(response);

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) {
        throw const FormatException(
          'A API não retornou uma lista de chamados.',
        );
      }

      final requests = decoded.map((item) {
        return _SupportRequest.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _requests
          ..clear()
          ..addAll(requests);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendRequest() async {
    final description = _descriptionController.text.trim();

    if (description.isEmpty) {
      _showMessage(
        'Preencha a descrição da solicitação.',
        isError: true,
      );
      return;
    }
    if (_sending) return;

    setState(() => _sending = true);

    try {
      final type = _ticketType.contains('Ajuda') ? 'Ajuda' : 'Erro';
      final response = await _http.post(
        _uri('/chamados'),
        headers: _headers,
        body: jsonEncode({
          'tipo': type,
          'descricao': description,
        }),
      );
      _checkResponse(response);

      final created = _SupportRequest.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map,
        ),
      );

      if (!mounted) return;
      setState(() {
        _requests.insert(0, created);
        _descriptionController.clear();
      });
      _showMessage('Solicitação enviada com sucesso!');
    } catch (error) {
      if (mounted) {
        _showMessage(_errorMessage(error), isError: true);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Erro ${response.statusCode}: ${response.body}';
      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  String _errorMessage(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFB42318) : const Color(0xFF000000),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 992;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SGSST / Área do Colaborador',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ajuda e Suporte',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 360, child: _formCard()),
                            const SizedBox(width: 24),
                            Expanded(child: _requestsCard()),
                          ],
                        )
                      else ...[
                        _formCard(),
                        const SizedBox(height: 20),
                        _requestsCard(),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _formCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Nova solicitação'),
          const SizedBox(height: 24),
          const _FieldLabel('Tipo'),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            value: _ticketType,
            isExpanded: true,
            decoration: _inputDecoration(),
            items: const [
              DropdownMenuItem(
                value: 'Solicitar Ajuda',
                child: Text('Solicitar Ajuda'),
              ),
              DropdownMenuItem(
                value: 'Reportar Erro',
                child: Text('Reportar Erro'),
              ),
            ],
            onChanged: _sending
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _ticketType = value);
                    }
                  },
          ),
          const SizedBox(height: 20),
          const _FieldLabel('Descrição'),
          const SizedBox(height: 7),
          TextField(
            controller: _descriptionController,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: _inputDecoration(
              hint: 'Descreva sua dúvida ou problema',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _sending ? null : _sendRequest,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Enviar solicitação',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Solicitações recentes'),
          const SizedBox(height: 24),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFB42318)),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _loadRequests,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          else if (_requests.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Nenhuma solicitação encontrada.',
                  style: TextStyle(color: _muted),
                ),
              ),
            )
          else
            _requestsTable(),
        ],
      ),
    );
  }

  Widget _requestsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 650),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.1),
            1: FlexColumnWidth(2.2),
            2: FlexColumnWidth(1.2),
            3: FlexColumnWidth(1.5),
          },
          border: TableBorder.all(
            color: const Color(0xFF9CA3AF),
            width: 0.7,
          ),
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Color(0xFFE5E7EB)),
              children: [
                _TableHeader('Tipo'),
                _TableHeader('Descrição'),
                _TableHeader('Usuário'),
                _TableHeader('Status'),
              ],
            ),
            ..._requests.map(
              (request) => TableRow(
                children: [
                  _TableCell(
                    Text(
                      request.type,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  _TableCell(Text(request.description)),
                  _TableCell(
                    Text(
                      request.user,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  _TableCell(_StatusBadge(status: request.status)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _muted,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.black),
      ),
    );
  }
}

class _SupportRequest {
  const _SupportRequest({
    required this.id,
    required this.type,
    required this.description,
    required this.user,
    required this.status,
  });

  final dynamic id;
  final String type;
  final String description;
  final String user;
  final String status;

  factory _SupportRequest.fromJson(Map<String, dynamic> json) {
    return _SupportRequest(
      id: json['id'],
      type: '${json['tipo'] ?? ''}',
      description: '${json['descricao'] ?? ''}',
      user: '${json['solicitante'] ?? 'Colaborador'}',
      status: '${json['status'] ?? 'Em andamento'}',
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;

    if (status == 'Concluída') {
      background = const Color(0xFFDCFCE7);
      foreground = const Color(0xFF166534);
    } else if (status == 'Em andamento') {
      background = const Color(0xFFDBEAFE);
      foreground = const Color(0xFF1D4ED8);
    } else {
      background = const Color(0xFFF3F4F6);
      foreground = const Color(0xFF374151);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: foreground,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: _inkColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: _inkColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      );
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: const TextStyle(
            color: _inkColor,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      );
}

class _TableCell extends StatelessWidget {
  const _TableCell(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: DefaultTextStyle(
          style: const TextStyle(color: Color(0xFF1F2937), fontSize: 12),
          child: child,
        ),
      );
}

const Color _inkColor = Color(0xFF0F172A);
