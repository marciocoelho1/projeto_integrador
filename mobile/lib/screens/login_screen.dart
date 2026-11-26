import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';
import 'recuperar_senha_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService auth;
  const LoginScreen({super.key, required this.auth});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _login = TextEditingController();
  final _senha = TextEditingController();
  bool _carregando = false;
  String? _erro;

  Future<void> _entrar() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      await widget.auth.entrar(_login.text, _senha.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen(auth: widget.auth)),
      );
    } catch (e) {
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    Text('Meu SGSST', style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 4),
                    Text('Sistema de Gestão de SST',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _login,
                      decoration: const InputDecoration(labelText: 'Usuário'),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _senha,
                      decoration: const InputDecoration(labelText: 'Senha'),
                      obscureText: true,
                      onSubmitted: (_) => _entrar(),
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 12),
                      Text(_erro!, style: const TextStyle(color: AppCores.vencido)),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _carregando
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RecuperarSenhaScreen(auth: widget.auth),
                                  ),
                                ),
                        child: const Text('Esqueci minha senha'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: _carregando ? null : _entrar,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppCores.petroleo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _carregando
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                            : const Text('Entrar',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
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