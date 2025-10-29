import 'package:flutter/material.dart';
import '../brand_logo.dart';
import '../theme.dart';
import 'login_page.dart';
import 'register_name_page.dart';

/// =============================================================
/// PANTALLA DE INICIO - "Comencemos"
/// =============================================================
/// Esta pantalla permite al usuario elegir entre:
/// - Iniciar sesión (redirige a [LoginPage])
/// - Registrarse (redirige a [RegisterNamePage])
///
/// Forma parte del flujo de autenticación inicial y se
/// registra en la aplicación con la ruta '/auth/choice'.
/// =============================================================
class ChoiceStart extends StatelessWidget {
  const ChoiceStart({super.key});

  /// Ruta registrada en app.dart
  static const route = '/auth/choice';

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),

                      /// Título principal
                      const Text(
                        'Comencemos',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: kInk,
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// Logotipo principal de la aplicación
                      const BrandLogo(size: 170),

                      const SizedBox(height: 28),

                      /// Botón para iniciar sesión
                      SizedBox(
                        width: 296,
                        height: 56,
                        child: FilledButton(
                          style: pillLav(), // Estilo morado definido en theme.dart
                          onPressed: () => Navigator.pushNamed(
                            context,
                            LoginPage.route,
                          ),
                          child: const Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: kInk,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// Botón para registrarse
                      SizedBox(
                        width: 296,
                        height: 56,
                        child: FilledButton(
                          style: pillBlue(), // Estilo azul definido en theme.dart
                          onPressed: () => Navigator.pushNamed(
                            context,
                            RegisterNamePage.route,
                          ),
                          child: const Text(
                            'Regístrate',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: kInk,
                            ),
                          ),
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
