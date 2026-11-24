import 'package:flutter/material.dart';

/// Design system do mockup "Carteira digital".
class AppCores {
  static const petroleo = Color(0xFF0B3B4A);
  static const areia = Color(0xFFF6F1E7);
  static const cartao = Color(0xFFFFFFFF);
  static const cinza = Color(0xFF5A6B70);
  static const valido = Color(0xFF1B7F5A);
  static const vencendo = Color(0xFFB8860B);
  static const vencido = Color(0xFFB3392F);
  static const pagina = Color(0xFFF2F2F0);
  static const hairline = Color(0xFFEAE3D6);
  static const tinta = Color(0xFF14181A);
}

class AppTheme {
  static ThemeData get tema => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppCores.areia,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppCores.petroleo,
          primary: AppCores.petroleo,
          surface: AppCores.cartao,
        ),
        //fontFamily: 'Inter',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w700,
            letterSpacing: -0.6, color: AppCores.petroleo,
          ),
          titleLarge: TextStyle(
            fontSize: 21, fontWeight: FontWeight.w700,
            letterSpacing: -0.4, color: AppCores.petroleo,
          ),
          titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600,
            letterSpacing: -0.2, color: AppCores.petroleo,
          ),
          bodyMedium: TextStyle(fontSize: 13.5, height: 1.45, color: AppCores.cinza),
          labelSmall: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      );
}

/// Cartão padrão do mockup: raio 20 e sombra suave.
class CartaoSgsst extends StatelessWidget {
  const CartaoSgsst({super.key, required this.child, this.cor});
  final Widget child;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cor ?? AppCores.cartao,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppCores.petroleo.withValues(alpha: 0.07),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}