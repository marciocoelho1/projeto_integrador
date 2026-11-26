import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Campo de texto padrão dos formulários (mesmo raio e cores dos cartões).
class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    required this.rotulo,
    required this.controlador,
    this.dica,
    this.obscuro = false,
    this.tipoTeclado,
    this.maxCaracteres,
    this.maxLinhas = 1,
    this.validador,
    this.aoSubmeter,
  });

  final String rotulo;
  final TextEditingController controlador;
  final String? dica;
  final bool obscuro;
  final TextInputType? tipoTeclado;
  final int? maxCaracteres;
  final int maxLinhas;
  final String? Function(String?)? validador;
  final void Function(String)? aoSubmeter;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      obscureText: obscuro,
      keyboardType: tipoTeclado,
      maxLength: maxCaracteres,
      maxLines: maxLinhas,
      validator: validador,
      onFieldSubmitted: aoSubmeter,
      decoration: InputDecoration(
        labelText: rotulo,
        hintText: dica,
        counterText: '',
        filled: true,
        fillColor: AppCores.pagina,
        border: _borda(AppCores.hairline),
        enabledBorder: _borda(AppCores.hairline),
        focusedBorder: _borda(AppCores.petroleo, largura: 1.6),
        errorBorder: _borda(AppCores.vencido),
        focusedErrorBorder: _borda(AppCores.vencido, largura: 1.6),
      ),
    );
  }

  OutlineInputBorder _borda(Color cor, {double largura = 1}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cor, width: largura),
      );
}

/// Lista suspensa padrão dos formulários.
class CampoSelecao<T> extends StatelessWidget {
  const CampoSelecao({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.opcoes,
    required this.aoMudar,
    this.validador,
  });

  final String rotulo;
  final T? valor;
  final List<DropdownMenuItem<T>> opcoes;
  final ValueChanged<T?> aoMudar;
  final String? Function(T?)? validador;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: valor,
      items: opcoes,
      onChanged: aoMudar,
      validator: validador,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: rotulo,
        filled: true,
        fillColor: AppCores.pagina,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppCores.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppCores.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppCores.petroleo, width: 1.6),
        ),
      ),
    );
  }
}

/// Campo de data que abre o calendário e devolve o valor em `yyyy-MM-dd`.
class CampoData extends StatelessWidget {
  const CampoData({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.aoEscolher,
    this.primeira,
    this.ultima,
  });

  /// Valor no formato ISO (`yyyy-MM-dd`) ou vazio.
  final String valor;
  final String rotulo;
  final ValueChanged<String> aoEscolher;
  final DateTime? primeira;
  final DateTime? ultima;

  @override
  Widget build(BuildContext context) {
    final selecionada = valor.isEmpty ? null : DateTime.tryParse(valor);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final escolhida = await showDatePicker(
          context: context,
          initialDate: selecionada ?? DateTime.now(),
          firstDate: primeira ?? DateTime(2000),
          lastDate: ultima ?? DateTime(2100),
          locale: const Locale('pt', 'BR'),
        );
        if (escolhida != null) {
          aoEscolher(
            '${escolhida.year.toString().padLeft(4, '0')}-'
            '${escolhida.month.toString().padLeft(2, '0')}-'
            '${escolhida.day.toString().padLeft(2, '0')}',
          );
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: rotulo,
          filled: true,
          fillColor: AppCores.pagina,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppCores.hairline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppCores.hairline),
          ),
        ),
        child: Text(
          valor.isEmpty
              ? 'Selecione'
              : '${valor.substring(8, 10)}/${valor.substring(5, 7)}/${valor.substring(0, 4)}',
          style: TextStyle(
            color: valor.isEmpty ? AppCores.cinza : AppCores.tinta,
            fontWeight: valor.isEmpty ? FontWeight.w400 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Botão de ação principal (petróleo, raio 16) do design do dashboard.
class BotaoPrimario extends StatelessWidget {
  const BotaoPrimario({
    super.key,
    required this.rotulo,
    required this.aoClicar,
    this.carregando = false,
    this.icone,
  });

  final String rotulo;
  final VoidCallback? aoClicar;
  final bool carregando;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: carregando ? null : aoClicar,
        icon: carregando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icone ?? Icons.check, size: 20),
        label: Text(
          carregando ? 'Salvando...' : rotulo,
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppCores.petroleo,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
