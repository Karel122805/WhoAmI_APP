// lib/src/ui/screens/splash_welcome.dart
import 'package:flutter/material.dart';
import '../brand_logo.dart';
import '../theme.dart';              // 👈 IMPORTA EL THEME (welcomeKicker, kInk, pillBlue)
import 'choice_start.dart';

class SplashWelcome extends StatelessWidget {
  const SplashWelcome({super.key});
  static const route = '/';

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const BrandLogo(size: 190),
                    const SizedBox(height: 20),
                    const Text('BIENVENIDO A', style: welcomeKicker),
                    const SizedBox(height: 8),
                    const Text(
                      'who am i?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: kInk,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 296,
                      height: 56,
                      child: FilledButton(
                        style: pillBlue(),
                        onPressed: () => Navigator.pushNamed(context, ChoiceStart.route),
                        child: const Text('Comenzar'),
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
