import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Tela Flutter correspondente ao módulo Angular de EPIs.
/// Pode ser chamada fora do main.dart:
/// home: const EpisScreen()
///
/// Configure a URL da API com:
/// --dart-define=API_BASE_URL=http://localhost:3000/api
class EpisScreen extends StatefulWidget {
  const EpisScreen({super.key});

  @override
  State<EpisScreen> createState() => _EpisScreenState();
}

class _EpisScreenState extends State<EpisScreen> {
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  static const _petroleum = Color(0xFF0B3B4A);
  static const _sand = Color(0xFFF6F1E7);
  static const _green = Color(0xFF1B7E5A);
  static const _red = Color(0xFFB3392F);
  static const _gold = Color(0xFFB8860B);

  final _searchController = TextEditingController();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  List<Map<String, dynamic>> _epis = [];
  List<Map<String, dynamic>> _entregas = [];
  List<Map<String, dynamic>> _colaboradores = [];

  bool _loading = false;
  bool _loadingEntregas = false;
  bool _saving = false;
  String _error = '';
  String _search = '';
  int _tab = 0;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<dynamic> _get(String path) async {
    final response = await http.get(_uri(path), headers: _headers);
    _check(response);
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<void> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    late http.Response response;
    final encoded = body == null ? null : jsonEncode(body);

    switch (method) {
      case 'POST':
        response = await http.post(_uri(path), headers: _headers, body: encoded);
        break;
      case 'PUT':
        response = await http.put(_uri(path), headers: _headers, body: encoded);
        break;
      case 'DELETE':
        response = await http.delete(_uri(path), headers: _headers);
        break;
      default:
        throw Exception('Método HTTP não suportado.');
    }
    _check(response);
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_apiError(response));
    }
  }

  String _apiError(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map && data['message'] != null) {
        return '${data['message']}';
      }
    } catch (_) {}
    return 'Erro ${response.statusCode}: ${response.body}';
  }

  Future<void> _refresh() async {
    await Future.wait([_loadEpis(), _loadEntregas()]);
  }

  Future<void> _loadEpis() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final data = await _get('/epis') as List;
      if (!mounted) return;
      setState(() => _epis = data.cast<Map<String, dynamic>>());
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadEntregas() async {
    if (_loadingEntregas) return;
    setState(() => _loadingEntregas = true);
    try {
      final data = await _get('/entregas-epis') as List;
      if (!mounted) return;
      setState(() => _entregas = data.cast<Map<String, dynamic>>());
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingEntregas = false);
    }
  }

  Future<void> _loadColaboradores() async {
    final data = await _get('/colaboradores') as List;
    _colaboradores = data.cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> get _filteredEpis {
    final term = _search.trim().toLowerCase();
    if (term.isEmpty) return _epis;
    return _epis.where((epi) {
      return '${epi['descricao'] ?? ''}'.toLowerCase().contains(term) ||
          '${epi['id'] ?? ''}'.contains(term) ||
          '${epi['ca'] ?? ''}'.contains(term);
    }).toList();
  }

  String _date(String? value) {
    if (value == null || value.isEmpty) return '—';
    try {
      return _dateFormat.format(DateTime.parse(value).toLocal());
    } catch (_) {
      return value;
    }
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? _red : _petroleum,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _confirm(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Confirmar ação'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _petroleum),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _editEpi(Map<String, dynamic> epi) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final current = await _get('/epis/${epi['id']}') as Map<String, dynamic>;
      if (!mounted) return;
      final updated = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => _EpiEditDialog(epi: current),
      );
      if (updated == null) return;

      final id = updated.remove('id');
      await _send('PUT', '/epis/$id', body: updated);
      await _loadEpis();
      _toast('EPI atualizado com sucesso!');
    } catch (e) {
      _toast(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteEpi(Map<String, dynamic> epi) async {
    if (_saving) return;
    final ok = await _confirm(
      'Excluir "${epi['descricao']}"? Esta ação não pode ser desfeita.',
    );
    if (!ok) return;

    setState(() => _saving = true);
    try {
      await _send('DELETE', '/epis/${epi['id']}');
      setState(() => _epis.removeWhere((item) => item['id'] == epi['id']));
      _toast('Registro excluído com sucesso!');
    } catch (e) {
      _toast(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _newDelivery() async {
    try {
      await _loadColaboradores();
      if (!mounted) return;
      if (_colaboradores.isEmpty) {
        _toast('Nenhum colaborador cadastrado foi encontrado.', error: true);
        return;
      }
      if (_epis.isEmpty) {
        _toast('Não há EPIs cadastrados.', error: true);
        return;
      }

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => _DeliveryDialog(
          colaboradores: _colaboradores,
          epis: _epis,
        ),
      );
      if (result == null) return;

      setState(() => _saving = true);
      await _send('POST', '/entregas-epis', body: result);
      await _refresh();
      _toast('Entrega registrada e estoque atualizado!');
    } catch (e) {
      _toast(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteDelivery(Map<String, dynamic> entrega) async {
    if (_saving) return;
    final ok = await _confirm(
      'Excluir a entrega de "${entrega['epi']}"? O estoque será estornado.',
    );
    if (!ok) return;

    setState(() => _saving = true);
    try {
      await _send('DELETE', '/entregas-epis/${entrega['id']}');
      await _refresh();
      _toast('Entrega excluída e estoque estornado!');
    } catch (e) {
      _toast(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: _petroleum),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFE3DED3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFE3DED3)),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: _sand,
        appBar: AppBar(
          backgroundColor: _petroleum,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Meu SGSST', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                _tab == 0 ? 'Gestão de EPIs' : 'Histórico de entregas',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Atualizar lista',
              onPressed: _saving ? null : _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: _loading && _epis.isEmpty
                ? const Center(child: CircularProgressIndicator(color: _petroleum))
                : RefreshIndicator(
                    onRefresh: _refresh,
                    color: _petroleum,
                    child: ListView(
                      padding: EdgeInsets.all(wide ? 28 : 16),
                      children: [
                        if (_error.isNotEmpty) _errorBanner(),
                        if (_tab == 0) _stockContent() else _deliveryContent(),
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _petroleum,
          foregroundColor: Colors.white,
          onPressed: _saving
              ? null
              : _tab == 0
                  ? () => _toast(
                        'O cadastro de novos EPIs pertence ao módulo de cadastramentos.',
                      )
                  : _newDelivery,
          icon: Icon(_tab == 0 ? Icons.add : Icons.assignment_turned_in_outlined),
          label: Text(_tab == 0 ? 'Novo EPI' : 'Entregar EPI'),
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFE4ECEC),
          selectedIndex: _tab,
          onDestinationSelected: (value) => setState(() => _tab = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Estoque',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'Entregas',
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBanner() => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8E8E5),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(_error, style: const TextStyle(color: _red, fontSize: 12)),
      );

  Widget _stockContent() {
    final lowStock = _epis.where((e) => (e['quantidade'] as num? ?? 0) <= 5).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Estoque de EPIs',
                style: TextStyle(
                  color: _petroleum,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _counter('${_epis.length} itens'),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _summaryCard('EPIs cadastrados', '${_epis.length}', Icons.shield_outlined)),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard('Estoque baixo', '$lowStock', Icons.warning_amber_rounded, color: _gold)),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _search = value),
          decoration: InputDecoration(
            hintText: 'Buscar por descrição, CA ou código',
            prefixIcon: const Icon(Icons.search, color: _petroleum),
            suffixIcon: _search.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _search = '');
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 15),
        if (_filteredEpis.isEmpty)
          _emptyState('Nenhum EPI encontrado.')
        else
          ..._filteredEpis.map(_epiCard),
      ],
    );
  }

  Widget _deliveryContent() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Histórico de entregas',
            style: TextStyle(color: _petroleum, fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '${_entregas.length} entregas registradas',
            style: const TextStyle(color: Color(0xFF657579), fontSize: 12),
          ),
          const SizedBox(height: 15),
          if (_loadingEntregas && _entregas.isEmpty)
            const Center(child: CircularProgressIndicator(color: _petroleum))
          else if (_entregas.isEmpty)
            _emptyState('Nenhuma entrega registrada.')
          else
            ..._entregas.map(_deliveryCard),
        ],
      );

  Widget _summaryCard(String label, String value, IconData icon, {Color color = _petroleum}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20)),
                Text(label, style: const TextStyle(color: Color(0xFF657579), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _counter(String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(color: const Color(0xFFE7ECE9), borderRadius: BorderRadius.circular(30)),
        child: Text(value, style: const TextStyle(color: _petroleum, fontSize: 11, fontWeight: FontWeight.w600)),
      );

  Widget _emptyState(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, color: Color(0xFF829093), size: 34),
            const SizedBox(height: 9),
            Text(message, style: const TextStyle(color: Color(0xFF657579), fontSize: 13)),
          ],
        ),
      );

  Widget _epiCard(Map<String, dynamic> epi) {
    final quantity = (epi['quantidade'] as num? ?? 0).toInt();
    final stockColor = quantity <= 5 ? _gold : _green;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 9, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(color: const Color(0xFFE8EEEE), borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.shield_outlined, color: _petroleum),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${epi['descricao'] ?? ''}', style: const TextStyle(color: _petroleum, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text('CA ${epi['ca'] ?? '—'}  ·  Código ${epi['id']}', style: const TextStyle(color: Color(0xFF657579), fontSize: 11)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => value == 'edit' ? _editEpi(epi) : _deleteEpi(epi),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Divider(height: 1, color: Color(0xFFECE8DF))),
          Wrap(
            spacing: 25,
            runSpacing: 10,
            children: [
              _detail('Quantidade em estoque', '$quantity', stockColor),
              _detail('Data de inclusão', _date(epi['inclusao']?.toString()), _petroleum),
              _detail('Validade', _date(epi['validade']?.toString()), _petroleum),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF829093), fontSize: 10)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _deliveryCard(Map<String, dynamic> item) => Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFE8EEEE),
              child: Icon(Icons.person_outline, color: _petroleum),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item['epi'] ?? ''}', style: const TextStyle(color: _petroleum, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('${item['colaborador'] ?? ''} · Matrícula ${item['matricula'] ?? '—'}', style: const TextStyle(color: Color(0xFF657579), fontSize: 11)),
                  Text('CA ${item['ca'] ?? '—'} · Qtd. ${item['quantidade'] ?? 0}', style: const TextStyle(color: Color(0xFF657579), fontSize: 11)),
                  Text(_date(item['dataEntrega']?.toString()), style: const TextStyle(color: Color(0xFF657579), fontSize: 10)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Excluir entrega e estornar estoque',
              onPressed: _saving ? null : () => _deleteDelivery(item),
              icon: const Icon(Icons.delete_outline, color: _red),
            ),
          ],
        ),
      );
}

class _EpiEditDialog extends StatefulWidget {
  final Map<String, dynamic> epi;
  const _EpiEditDialog({required this.epi});

  @override
  State<_EpiEditDialog> createState() => _EpiEditDialogState();
}

class _EpiEditDialogState extends State<_EpiEditDialog> {
  late final TextEditingController _description;
  late final TextEditingController _quantity;
  late final TextEditingController _inclusion;
  late final TextEditingController _validity;
  late final TextEditingController _ca;

  @override
  void initState() {
    super.initState();
    _description = TextEditingController(text: '${widget.epi['descricao'] ?? ''}');
    _quantity = TextEditingController(text: '${widget.epi['quantidade'] ?? 0}');
    _inclusion = TextEditingController(text: '${widget.epi['inclusao'] ?? ''}');
    _validity = TextEditingController(text: '${widget.epi['validade'] ?? ''}');
    _ca = TextEditingController(text: '${widget.epi['ca'] ?? ''}');
  }

  @override
  void dispose() {
    _description.dispose();
    _quantity.dispose();
    _inclusion.dispose();
    _validity.dispose();
    _ca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Editar EPI', style: TextStyle(color: Color(0xFF0B3B4A))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_description, 'Descrição'),
              _field(_quantity, 'Quantidade', numeric: true),
              _field(_inclusion, 'Inclusão (AAAA-MM-DD)'),
              _field(_validity, 'Validade (AAAA-MM-DD)'),
              _field(_ca, 'Certificado de Aprovação (CA)', numeric: true, maxLength: 10),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B3B4A)),
            onPressed: _save,
            child: const Text('Salvar'),
          ),
        ],
      );

  Widget _field(TextEditingController controller, String label, {bool numeric = false, int? maxLength}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          maxLength: maxLength,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: label, counterText: ''),
        ),
      );

  void _save() {
    final quantity = int.tryParse(_quantity.text);
    final ca = _ca.text;
    if (_description.text.trim().isEmpty ||
        quantity == null ||
        quantity < 0 ||
        !RegExp(r'^\d{0,10}$').hasMatch(ca)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos e informe uma quantidade inteira não negativa.')),
      );
      return;
    }
    Navigator.pop(context, {
      'id': widget.epi['id'],
      'descricao': _description.text.trim(),
      'quantidade': quantity,
      'inclusao': _inclusion.text.trim(),
      'validade': _validity.text.trim(),
      'ca': ca,
    });
  }

}

class _DeliveryDialog extends StatefulWidget {
  final List<Map<String, dynamic>> colaboradores;
  final List<Map<String, dynamic>> epis;

  const _DeliveryDialog({required this.colaboradores, required this.epis});

  @override
  State<_DeliveryDialog> createState() => _DeliveryDialogState();
}

class _DeliveryDialogState extends State<_DeliveryDialog> {
  Map<String, dynamic>? _colaborador;
  Map<String, dynamic>? _epi;
  final _quantity = TextEditingController(text: '1');
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Registrar entrega'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _colaborador,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Colaborador'),
                items: widget.colaboradores.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text('${item['nome']} · ${item['matricula']}', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _colaborador = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _epi,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'EPI'),
                items: widget.epis.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text('${item['descricao']} (estoque: ${item['quantidade']})', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _epi = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantidade'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(DateFormat('dd/MM/yyyy').format(_date)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B3B4A)),
            onPressed: _save,
            child: const Text('Registrar entrega'),
          ),
        ],
      );

  Future<void> _selectDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (result != null) setState(() => _date = result);
  }

  void _save() {
    final quantity = int.tryParse(_quantity.text);
    final epiStock = (_epi?['quantidade'] as num?)?.toInt() ?? 0;
    if (_colaborador == null ||
        _epi == null ||
        quantity == null ||
        quantity <= 0 ||
        quantity > epiStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione colaborador e EPI e informe quantidade válida dentro do estoque.')),
      );
      return;
    }
    Navigator.pop(context, {
      'colaboradorId': _colaborador!['id'],
      'epiId': _epi!['id'],
      'quantidade': quantity,
      'dataEntrega': DateFormat('yyyy-MM-dd').format(_date),
      'assinatura': _colaborador!['nome'],
    });
  }
}
