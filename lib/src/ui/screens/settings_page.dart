import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../brand_logo.dart';
import '../theme.dart';
import 'login_page.dart';
import 'package:whoami_app/services/biometric_auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  static const route = '/settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _role;   // 'Cuidador' | 'Consultante'
  String? _name;
  String? _email;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserMeta();
  }

  Future<void> _loadUserMeta() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      _email = user.email;

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = snap.data() ?? {};
      final first = (data['firstName'] as String?)?.trim();
      final last  = (data['lastName'] as String?)?.trim();
      _role = (data['role'] as String?)?.trim() ?? 'Consultante';
      _name = [first, last].where((e) => (e ?? '').isNotEmpty).join(' ');
      _name = (_name?.isNotEmpty ?? false)
          ? _name
          : (user.displayName ?? _email?.split('@').first ?? 'Usuario');
    } catch (_) {
      // no crashea
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await BiometricAuthService.instance.setAppLockEnabled(false); // opcional
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, LoginPage.route, (_) => false);
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature próximamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = _role ?? 'Consultante';
    final roleColor =
        role == 'Cuidador' ? const Color(0xFF00BFA6) : const Color(0xFF2196F3);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: CircularProgressIndicator(),
                    )
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 56,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 0, top: 8,
                                    child: IconButton.filled(
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(0xFFEAEAEA),
                                        shape: const CircleBorder(),
                                        fixedSize: const Size(40, 40),
                                      ),
                                      onPressed: () => Navigator.maybePop(context),
                                      icon: const Icon(Icons.home_outlined, color: kInk),
                                    ),
                                  ),
                                  const Center(
                                    child: Text(
                                      'Ajustes',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: kInk,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Align(child: BrandLogo(size: 120)),
                            const SizedBox(height: 12),

                            // Identidad/rol
                            Column(
                              children: [
                                Text(
                                  _name ?? '',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: kInk,
                                  ),
                                ),
                                if (_email != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      _email!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF8A8A8A),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: roleColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: roleColor.withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    role,
                                    style: TextStyle(
                                      color: roleColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),
                            const Text(
                              'Gestiona tu cuenta',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Color(0xFF8A8A8A)),
                            ),
                            const SizedBox(height: 18),

                            // PERFIL (placeholder)
                            SizedBox(
                              height: 56,
                              child: FilledButton.icon(
                                style: pillBlue(),
                                onPressed: () => _comingSoon('Perfil'),
                                icon: const Icon(Icons.person_outline),
                                label: const Text('Perfil'),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Opciones según rol (placeholders)
                            if (role == 'Cuidador') ...[
                              SizedBox(
                                height: 56,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFB2DFDB),
                                    shape: const StadiumBorder(),
                                    foregroundColor: const Color(0xFF00695C),
                                  ),
                                  onPressed: () => _comingSoon('Vincular consultante'),
                                  icon: const Icon(Icons.link_rounded),
                                  label: const Text('Vincular consultante'),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ] else ...[
                              SizedBox(
                                height: 56,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFBBDEFB),
                                    shape: const StadiumBorder(),
                                    foregroundColor: const Color(0xFF0D47A1),
                                  ),
                                  onPressed: () => _comingSoon('Mi cuidador'),
                                  // 🔧 Ícono compatible (antes: shield_person_rounded)
                                  icon: const Icon(Icons.verified_user_outlined),
                                  label: const Text('Mi cuidador'),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // CERRAR SESIÓN (funcional)
                            SizedBox(
                              height: 56,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF9EA3),
                                  shape: const StadiumBorder(),
                                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                onPressed: _logout,
                                icon: const Icon(Icons.logout_rounded),
                                label: const Text('Cerrar Sesión'),
                              ),
                            ),

                            const SizedBox(height: 28),
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
