import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../brand_logo.dart';
import '../theme.dart';
import 'settings_page.dart';

// 👇 Importa la vista de Guías rápidas (cuidador)
import 'quick_guides_page.dart';

class HomeCaregiverPage extends StatefulWidget {
  const HomeCaregiverPage({super.key, this.displayName});
  static const route = '/home/caregiver';

  final String? displayName;

  @override
  State<HomeCaregiverPage> createState() => _HomeCaregiverPageState();
}

class _HomeCaregiverPageState extends State<HomeCaregiverPage> {
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
                      // Engrane -> Ajustes
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

                      // 👉 Nombre que reacciona a cambios de Auth y Firestore
                      StreamBuilder<User?>(
                        stream: FirebaseAuth.instance.userChanges(),
                        builder: (context, authSnap) {
                          final user = authSnap.data ?? FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            return const SizedBox();
                          }
                          final uid = user.uid;

                          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .snapshots(),
                            builder: (context, docSnap) {
                              String name = 'Cuidador';

                              // 1) Firestore first/last (preferido)
                              if (docSnap.hasData && docSnap.data!.data() != null) {
                                final data = docSnap.data!.data()!;
                                final first = (data['firstName'] as String?)?.trim() ?? '';
                                final last  = (data['lastName']  as String?)?.trim() ?? '';
                                final fsName = [first, last]
                                    .where((e) => e.isNotEmpty)
                                    .join(' ');
                                if (fsName.isNotEmpty) name = fsName;
                              }

                              // 2) Fallback a displayName de Auth
                              if (name == 'Cuidador') {
                                final dn = (user.displayName ?? '').trim();
                                if (dn.isNotEmpty) name = dn;
                              }

                              // 3) Fallback a parte local del correo
                              if (name == 'Cuidador') {
                                final mail = user.email ?? '';
                                if (mail.contains('@')) {
                                  name = mail.split('@').first;
                                }
                              }

                              // 4) Fallback final
                              name = name.isNotEmpty ? name : (widget.displayName ?? 'Cuidador');

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

                      // 🔹 Botón Pacientes (antes "Ver pacientes")
                      _PillButton(
                        color: kPurple,
                        icon: Icons.people_outline,
                        text: 'Pacientes',
                        onTap: () {
                          // TODO: conectar a ver pacientes
                        },
                      ),

                      // Guías Rápidas
                      _PillButton(
                        color: kPurple,
                        icon: Icons.menu_book_outlined,
                        text: 'Guías Rápidas',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const QuickGuidesPage()),
                          );
                        },
                      ),

                      _PillButton(
                        color: kPurple,
                        icon: Icons.event_note_outlined,
                        text: 'Calendario de Recuerdos',
                        onTap: () {
                          // TODO: conectar a calendario
                        },
                      ),
                      _PillButton(
                        color: kPurple,
                        icon: Icons.chat_bubble_outline,
                        text: 'ChatWhoAmI',
                        onTap: () {
                          // TODO: conectar a chat
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
