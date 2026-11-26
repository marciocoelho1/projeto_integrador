import 'package:flutter/foundation.dart';

import '../config/api_config.dart';

/// Decide se a próxima requisição paga o prazo longo de "servidor frio".
///
/// O Render hiberna no plano gratuito e a primeira chamada pode levar cerca de
/// dois minutos. Em vez de aumentar o timeout de `todas` as chamadas (o que
/// deixaria qualquer erro de rede lento demais), só a primeira requisição de
/// cada sessão usa [ApiConfig.timeoutFrio]; ao ser respondida ela "acorda" a
/// API e as seguintes voltam ao [ApiConfig.timeout] normal.
class ControleServidorFrio {
  ControleServidorFrio._();

  static final ControleServidorFrio instancia = ControleServidorFrio._();

  /// A API ainda pode estar dormindo. Começa `true` e só cai para `false`
  /// quando alguma requisição recebe resposta (de qualquer status: uma
  /// resposta 401 prova que o servidor está acordado).
  bool _frio = true;

  bool get frio => _frio;

  /// Notifica a tela de login que a próxima chamada vai esperar o servidor.
  final ValueNotifier<bool> acordando = ValueNotifier<bool>(false);

  /// Prazo a usar nesta requisição.
  Duration get prazo => _frio ? ApiConfig.timeoutFrio : ApiConfig.timeout;

  /// Marca que a chamada começou e alerta a interface se for a "fria".
  void iniciar() {
    if (_frio) acordando.value = true;
  }

  /// Marca que o servidor respondeu: a partir daqui vale o prazo normal.
  void aquecer() {
    if (!_frio) return;
    _frio = false;
    acordando.value = false;
  }

  /// Chamada encerrada sem resposta (timeout/erro de rede). A próxima tenta
  /// de novo com prazo longo, porque o servidor pode não ter acordado.
  void encerrarSemResposta() {
    acordando.value = false;
  }

  /// Usado nos testes e ao sair da conta.
  @visibleForTesting
  void reiniciar() {
    _frio = true;
    acordando.value = false;
  }
}
