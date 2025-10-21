import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme.dart';
import 'settings_page.dart';
import '../user_avatar.dart';                    // 👈 avatar reutilizable

// 👇 Vistas
import 'tips_page.dart';
import 'game_page.dart';
import 'motivational_phrases_page.dart';

class HomeConsultantPage extends StatelessWidget {
  const HomeConsultantPage({super.key, this.displayName});
  static const route = '/home/consultant';

  final String? displayName;

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
                              MaterialPageRoute(builder: (_) => const SettingsPage()),
                            );
                          },
                          icon: const Icon(Icons.settings, color: kInk, size: 28),
                        ),
                      ),

                      // 👇 Foto del usuario (o avatar por defecto). Solo visual.
                      const UserAvatar(radius: 60),
                      const SizedBox(height: 12),

                      // 👇 Nombre reactivo (Firestore/Auth) con fallbacks
                      StreamBuilder<User?>(
                        stream: FirebaseAuth.instance.userChanges(),
                        builder: (context, authSnap) {
                          final user = authSnap.data ?? FirebaseAuth.instance.currentUser;
                          if (user == null) return const SizedBox();
                          final uid = user.uid;

                          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .snapshots(),
                            builder: (context, docSnap) {
                              String name = 'Usuario';

                              // 1) Firestore first/last
                              if (docSnap.hasData && docSnap.data!.data() != null) {
                                final data = docSnap.data!.data()!;
                                final first = (data['firstName'] as String?)?.trim() ?? '';
                                final last  = (data['lastName']  as String?)?.trim() ?? '';
                                final fsName = [first, last].where((e) => e.isNotEmpty).join(' ');
                                if (fsName.isNotEmpty) name = fsName;
                              }

                              // 2) displayName de Auth
                              if (name == 'Usuario') {
                                final dn = (user.displayName ?? '').trim();
                                if (dn.isNotEmpty) name = dn;
                              }

                              // 3) parte local del correo
                              if (name == 'Usuario') {
                                final mail = user.email ?? '';
                                if (mail.contains('@')) name = mail.split('@').first;
                              }

                              // 4) fallback final al argumento
                              name = name.isNotEmpty ? name : (displayName ?? 'Usuario');

                              return Text(
                                'Bienvenido $name',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: kInk,
                                ),
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 8),
                      const Text('Selecciona una opción', style: TextStyle(color: kGrey1)),
                      const SizedBox(height: 20),

                      // >>> BOTONES
                      _PillButton(
                        color: kBlue,
                        icon: Icons.menu_book_outlined,
                        text: 'Consejos',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const TipsPage()));
                        },
                      ),
                      _PillButton(
                        color: kBlue,
                        icon: Icons.auto_stories_outlined,
                        text: 'Frases motivadoras',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MotivationalPhrasesPage()));
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
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const GamePage()));
                        },
                      ),

                      const SizedBox(height: 1),
                      _PillButton(
                        color: const Color(0xFFFF9AA0),
                        icon: Icons.warning_amber_rounded,
                        text: 'Emergencia',
                        onTap: () => _showComingSoonDialog(context),
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk),
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
      content: const Text('Muy pronto este botón avisará al cuidador con una notificación.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}
