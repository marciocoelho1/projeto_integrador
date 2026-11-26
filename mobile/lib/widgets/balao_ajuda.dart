import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Baleao flutuante do atendimento, presente em todas as telas internas.
///
/// Comportamento pedido: ele aparece inteiro quando o usuario fica parado e se
/// esconde parcialmente (vira so o icone) enquanto o usuario navega. "Navegar"
/// inclui trocar de aba ou rolar a lista — qualquer sinal de que a tela esta em
/// uso. Depois de [segundosParaReexibir] sem atividade, ele volta inteiro.
class BalaoAjuda extends StatefulWidget {
  final VoidCallback aoTocar;
  final int segundosParaReexibir;

  const BalaoAjuda({
    super.key,
    required this.aoTocar,
    this.segundosParaReexibir = 4,
  });

  @override
  State<BalaoAjuda> createState() => BalaoAjudaState();
}

class BalaoAjudaState extends State<BalaoAjuda> {
  bool _recolhido = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Chame quando o usuario navegar (trocar de aba, abrir uma tela ou rolar).
  void sinalizarNavegacao() {
    _timer?.cancel();
    if (!_recolhido && mounted) setState(() => _recolhido = true);
    _timer = Timer(Duration(seconds: widget.segundosParaReexibir), () {
      if (mounted) setState(() => _recolhido = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedAlign(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 4, bottom: 4),
        child: Material(
          color: AppCores.petroleo,
          elevation: 6,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              sinalizarNavegacao();
              widget.aoTocar();
            },
            child: AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _recolhido ? 13 : 16,
                  vertical: 11,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.support_agent, color: Colors.white, size: 22),
                    // O texto sai de cena por largura zero para o baleao encolher.
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      width: _recolhido ? 0 : 74,
                      // O texto fica em largura fixa e o ClipRect o corta enquanto
                      // o container encolhe; assim o baleao vira so o icone.
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: 1,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Text(
                              'Ajuda',
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Casca das telas internas: aplica o fundo, a barra e o baleao de ajuda.
///
/// Fica por cima do corpo (nao empurra o conteudo) e marca o baleao como
/// "navegando" sempre que a tela troca de aba ou o usuario rola a lista.
class CascaComAjuda extends StatefulWidget {
  final Widget child;
  final VoidCallback aoAbrirAjuda;
  final Object? gatilhoDeNavegacao;

  const CascaComAjuda({
    super.key,
    required this.child,
    required this.aoAbrirAjuda,
    this.gatilhoDeNavegacao,
  });

  @override
  State<CascaComAjuda> createState() => CascaComAjudaState();
}

class CascaComAjudaState extends State<CascaComAjuda> {
  final GlobalKey<BalaoAjudaState> _chaveBalao = GlobalKey<BalaoAjudaState>();

  /// Recolhe o baleao: use quando o usuario trocar de tela ou de aba.
  void sinalizarNavegacao() => _chaveBalao.currentState?.sinalizarNavegacao();

  @override
  void didUpdateWidget(CascaComAjuda oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trocar de aba e uma navegacao: o baleao se recolhe e volta depois.
    if (oldWidget.gatilhoDeNavegacao != widget.gatilhoDeNavegacao) {
      _chaveBalao.currentState?.sinalizarNavegacao();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notificacao) {
        if (notificacao is ScrollStartNotification ||
            notificacao is ScrollUpdateNotification) {
          _chaveBalao.currentState?.sinalizarNavegacao();
        }
        return false;
      },
      child: Stack(
        children: [
          widget.child,
          Positioned(
            right: 12,
            bottom: 16,
            child: BalaoAjuda(key: _chaveBalao, aoTocar: widget.aoAbrirAjuda),
          ),
        ],
      ),
    );
  }
}
