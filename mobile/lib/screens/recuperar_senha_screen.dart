import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/toast.dart';
import '../services/auth_service.dart';
import '../widgets/campo_formulario.dart';

/// Porta de `src/app/tela-recuperar-senha`: solicita a recuperação em
/// POST /api/auth/recuperar-senha e mostra o retorno do backend.
class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final _login = TextEditingController();
  bool _enviando = false;
  String? _mensagem;
  String? _erro;

  @override
  void dispose() {
    _login.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_enviando) return;
    if (_login.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o usuário ou e-mail cadastrado.');
      return;
    }

    setState(() {
      _enviando = true;
      _erro = null;
      _mensagem = null;
    });
    try {
      final mensagem = await widget.auth.recuperarSenha(_login.text);
      if (!mounted) return;
      setState(() => _mensagem = mensagem);
      Toast.sucesso(context, mensagem);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.areia,
      appBar: AppBar(
        backgroundColor: AppCores.petroleo,
        foregroundColor: Colors.white,
        title: const Text('Recuperar senha'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: CartaoSgsst(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Recuperar senha',
                        style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Informe o usuário ou e-mail cadastrado. O SESMT valida a '
                      'solicitação e libera a redefinição.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    CampoTexto(
                      rotulo: 'Usuário ou e-mail',
                      controlador: _login,
                      aoSubmeter: (_) => _enviar(),
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 12),
                      Text(_erro!, style: const TextStyle(color: AppCores.vencido)),
                    ],
                    if (_mensagem != null) ...[
                      const SizedBox(height: 12),
                      Text(_mensagem!, style: const TextStyle(color: AppCores.valido)),
                    ],
                    const SizedBox(height: 24),
                    BotaoPrimario(
                      rotulo: 'Solicitar recuperação',
                      carregando: _enviando,
                      icone: Icons.lock_reset,
                      aoClicar: _enviar,
                    ),
                    TextButton(
                      onPressed: _enviando ? null : () => Navigator.of(context).pop(),
                      child: const Text('Voltar para o login'),
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
