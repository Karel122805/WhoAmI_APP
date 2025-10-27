// lib/src/ui/screens/home_caregiver.dart
//
// Pantalla principal del rol "Cuidador".
// Incluye badge rojo en la campanita con el número de notificaciones pendientes.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme.dart';
import 'settings_page.dart';
import '../user_avatar.dart';
import 'quick_guides_page.dart';
import 'patients_list_page.dart';
import 'calendar_page.dart';
import 'notifications_page.dart';
import 'package:whoami_app/services/memories_scheduler.dart';
import 'package:whoami_app/services/notifications_service.dart';

class HomeCaregiverPage extends StatefulWidget {
  const HomeCaregiverPage({super.key, this.displayName});
  static const route = '/home/caregiver';

  final String? displayName;

  @override
  State<HomeCaregiverPage> createState() => _HomeCaregiverPageState();
}

class _HomeCaregiverPageState extends State<HomeCaregiverPage> {
  int _notifCount = 0;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      MemoriesScheduler.scheduleAllForUser(uid).whenComplete(_loadNotifCount);
    } else {
      _loadNotifCount();
    }
  }

  Future<void> _loadNotifCount() async {
    final pending = await NotificationsService.pendingNotificationRequests();
    if (!mounted) return;
    setState(() => _notifCount = pending.length);
  }

  Future<void> _openNotifications() async {
    await Navigator.pushNamed(context, NotificationsPage.route);
    await _loadNotifCount();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Contenido principal desplazable
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 72, 20, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const UserAvatar(radius: 60),
                        const SizedBox(height: 12),

                        // Nombre dinámico del cuidador
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
                                String name = 'Cuidador';

                                if (docSnap.hasData && docSnap.data!.data() != null) {
                                  final data = docSnap.data!.data()!;
                                  final first = (data['firstName'] as String?)?.trim() ?? '';
                                  final last = (data['lastName'] as String?)?.trim() ?? '';
                                  final fsName = [first, last].where((e) => e.isNotEmpty).join(' ');
                                  if (fsName.isNotEmpty) name = fsName;
                                }

                                if (name == 'Cuidador') {
                                  final dn = (user.displayName ?? '').trim();
                                  if (dn.isNotEmpty) name = dn;
                                }

                                if (name == 'Cuidador') {
                                  final mail = user.email ?? '';
                                  if (mail.contains('@')) name = mail.split('@').first;
                                }

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

                        _PillButton(
                          color: kPurple,
                          icon: Icons.people_outline,
                          text: 'Pacientes',
                          onTap: () {
                            Navigator.pushNamed(context, PatientsListPage.route);
                          },
                        ),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CalendarPage()),
                            );
                          },
                        ),
                        _PillButton(
                          color: kPurple,
                          icon: Icons.chat_bubble_outline,
                          text: 'ChatWhoAmI',
                          onTap: () {
                            // Implementación futura del chat
                          },
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Botón de Ajustes (izquierda)
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: kInk, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                    tooltip: 'Ajustes',
                  ),
                ),
              ),
            ),

            // Campanita con badge de notificaciones (derecha)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4),
                  child: _NotificationBell(
                    count: _notifCount,
                    onTap: _openNotifications,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Campanita con badge rojo reutilizable
class _NotificationBell extends StatelessWidget {
  const _NotificationBell({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showBadge = count > 0;
    final display = count > 99 ? '99+' : count.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.notifications_none_rounded, color: kInk, size: 28),
          tooltip: 'Notificaciones',
        ),
        if (showBadge)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 18),
              alignment: Alignment.center,
              child: Text(
                display,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Botón con forma de pastilla reutilizable
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
