import 'package:flutter/material.dart';
import '../brand_logo.dart';
import '../theme.dart';
import 'settings_page.dart'; 

class HomeCaregiverPage extends StatelessWidget {
  const HomeCaregiverPage({super.key, this.displayName});
  static const route = '/home/caregiver';

  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final name = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : 'Cuidador';

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)),
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
                      // Engrane (ahora abre Ajustes)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsPage()),
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
                      const Text('Selecciona una opción',
                          style: TextStyle(color: kGrey1)),
                      const SizedBox(height: 20),

                      _PillButton(
                        color: kPurple,
                        icon: Icons.person_add_outlined,
                        text: 'Registrar paciente',
                        onTap: () {},
                      ),
                      _PillButton(
                        color: kPurple,
                        icon: Icons.people_outline,
                        text: 'Ver pacientes',
                        onTap: () {},
                      ),
                      _PillButton(
                        color: kPurple,
                        icon: Icons.menu_book_outlined,
                        text: 'Guías Rápidas',
                        onTap: () {},
                      ),
                      _PillButton(
                        color: kPurple,
                        icon: Icons.event_note_outlined,
                        text: 'Calendario de Recuerdos',
                        onTap: () {},
                      ),
                      _PillButton(
                        color: kPurple,
                        icon: Icons.chat_bubble_outline,
                        text: 'ChatWhoAmI',
                        onTap: () {},
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
