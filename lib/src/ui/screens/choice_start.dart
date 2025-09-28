import 'package:flutter/material.dart';
import '../brand_logo.dart';
import '../theme.dart';
import 'login_page.dart';
import 'register_name_page.dart';

class ChoiceStart extends StatelessWidget {
  const ChoiceStart({super.key});
  static const route = '/choice';

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const Text('Comencemos',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: kInk)),
                      const SizedBox(height: 16),
                      const BrandLogo(size: 170),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: 296, height: 56,
                        child: FilledButton(
                          style: pillLav(),
                          onPressed: () => Navigator.pushNamed(context, LoginPage.route),
                          child: const Text('Iniciar sesión'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 296, height: 56,
                        child: FilledButton(
                          style: pillBlue(),
                          onPressed: () => Navigator.pushNamed(context, RegisterNamePage.route),
                          child: const Text('Registrate'),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
