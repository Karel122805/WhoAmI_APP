import 'package:flutter/material.dart';
import '../brand_logo.dart';
import '../theme.dart';
import 'settings_page.dart';

// 👇 Vistas
import 'tips_page.dart';
import 'game_page.dart'; // <- corregido (antes: games_page.dart)
import 'motivational_phrases_page.dart'; // Frases motivadoras

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
                            MaterialPageRoute(builder: (_) => const TipsPage()),
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
                            MaterialPageRoute(builder: (_) => const MotivationalPhrasesPage()),
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
                              builder: (_) => const GamePage(), // <- corregido (antes: GamesPage)
                            ),
                          );
                        },
                      ),

                      // 🔴 Botón de EMERGENCIA (alineado igual que los demás)
                      const SizedBox(height: 1),
                      _PillButton(
                        color: const Color(0xFFFF9AA0), // tono del ejemplo
                        icon: Icons.warning_amber_rounded,
                        text: 'Emergencia',
                        onTap: () async {
                          _showComingSoonDialog(context);
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

// ===================== COMPONENTES =====================
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

// Diálogo de “próximamente”
void _showComingSoonDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Emergencia'),
      content: const Text(
        'Muy pronto este botón avisará al cuidador con una notificación.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}
