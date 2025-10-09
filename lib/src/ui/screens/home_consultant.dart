import 'package:flutter/material.dart';
import '../brand_logo.dart';
import '../theme.dart';
import 'settings_page.dart';

// 👇 Vistas
import 'tips_page.dart';
import 'games_page.dart';
import 'motivational_phrases_page.dart'; // <-- NUEVO

class HomeConsultantPage extends StatelessWidget {
  const HomeConsultantPage({super.key, this.displayName});
  static const route = '/home/consultant';

  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final name = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : 'Usuario';

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1),
      ),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.settings, color: kInk, size: 28),
                        ),
                      ),
                      const BrandLogo(size: 120),
                      const SizedBox(height: 12),
                      Text(
                        'Bienvenido $name',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: kInk,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Selecciona una opción',
                        style: TextStyle(color: kGrey1),
                      ),
                      const SizedBox(height: 20),

                      // >>> BOTONES
                      _PillButton(
                        color: kBlue,
                        icon: Icons.menu_book_outlined,
                        text: 'Consejos',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TipsPage(),
                            ),
                          );
                        },
                      ),
                      _PillButton(
                        color: kBlue,
                        icon: Icons.auto_stories_outlined,
                        text: 'Frases motivadoras',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MotivationalPhrasesPage(),
                            ),
                          );
                        },
                      ),
                      _PillButton(
                        color: kBlue,
                        icon: Icons.event_note_outlined,
                        text: 'Calendario de recuerdos',
                        onTap: () {
                          // TODO: Conectar a la vista de Calendario
                        },
                      ),
                      _PillButton(
                        color: kBlue,
                        icon: Icons.chat_bubble_outline,
                        text: 'ChatWhoAmI',
                        onTap: () {
                          // TODO: Conectar a la vista de Chat
                        },
                      ),
                      _PillButton(
                        color: kBlue,
                        icon: Icons.videogame_asset_outlined,
                        text: 'Juegos',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GamesPage(),
                            ),
                          );
                        },
                      ),

                      // 🔴 Botón de EMERGENCIA
                      const SizedBox(height: 8),
                      _PillButton(
                        color: Color(0xFFFF9AA0), // 👈 tono rosado/rojo pastel
                        icon: Icons.warning_amber_rounded,
                        text: 'Emergencia',
                        onTap: () {
                          // Aquí puedes poner la acción de emergencia:
                          // llamar, mostrar contactos o alerta sonora.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Función de emergencia activada',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        },
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

// ===================== COMPONENTE REUTILIZABLE =====================
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.color,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: kInk,
            shape: const StadiumBorder(),
            elevation: 0,
          ),
          onPressed: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: kInk),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
