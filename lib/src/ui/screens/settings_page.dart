import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/patients_service.dart';
import '../brand_logo.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  static const route = '/settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _db = FirebaseFirestore.instance;
  late final PatientsService _svc;

  User get _user => FirebaseAuth.instance.currentUser!;
  String get _uid => _user.uid;

  // 🎨 Paleta local
  static const Color kPurple = Color(0xFFD6A7F4);
  static const Color kBlue = Color(0xFF9ED3FF);
  static const Color kPink = Color(0xFFFFB3B3);
  static const Color kInk = Color(0xFF111111);

  @override
  void initState() {
    super.initState();
    _svc = PatientsService(_db);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, color: kInk),
        ),
        title: const Text(
          'Ajustes',
          style: TextStyle(color: kInk, fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  const BrandLogo(size: 120),
                  const SizedBox(height: 18),

                  // === Información del usuario ===
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _db.collection('users').doc(_uid).snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        );
                      }

                      final me = snap.data?.data() ?? {};
                      final role = (me['role'] as String?)?.trim() ?? '';
                      final firstName = (me['firstName'] as String?)?.trim() ?? '';
                      final lastName = (me['lastName'] as String?)?.trim() ?? '';
                      final myName = [firstName, lastName].where((e) => e.isNotEmpty).join(' ');
                      final caregiverId = me['caregiverId'] as String?;

                      // 🎨 Botón de rol con colores más fuertes
                      final roleButtonColor =
                          role == 'Cuidador' ? const Color(0xFFBE83F0) : const Color(0xFF6BB5F5);
                      final roleButtonBg =
                          role == 'Cuidador' ? const Color(0xFFEAD8FB) : const Color(0xFFD4EBFF);

                      final roleButton = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: roleButtonBg,
                          border: Border.all(color: roleButtonColor, width: 1.7),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Text(
                          role.isEmpty ? 'Sin rol' : role,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: roleButtonColor,
                            fontSize: 17,
                            letterSpacing: 0.2,
                          ),
                        ),
                      );

                      // === Info extra según el rol ===
                      Widget? extra;
                      if (role == 'Consultante') {
                        if (caregiverId != null && caregiverId.isNotEmpty) {
                          extra = FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            future: _db.collection('users').doc(caregiverId).get(),
                            builder: (context, cs) {
                              if (cs.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 10),
                                  child: _InfoCard(child: Text('Cargando cuidador…')),
                                );
                              }
                              final data = cs.data?.data();
                              if (data == null) return const SizedBox.shrink();
                              final name = (data['displayName'] ??
                                      '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}')
                                  .toString()
                                  .trim();
                              if (name.isEmpty) return const SizedBox.shrink();
                              return _InfoCard(
                                child: Row(
                                  children: [
                                    const Icon(Icons.verified_user, color: Colors.black54),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Tu cuidador: $name',
                                        style: const TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                      } else if (role == 'Cuidador') {
                        extra = StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
                          stream: _svc.streamPatientsOfCaregiver(_uid),
                          builder: (context, ps) {
                            final patients = (ps.data ?? [])
                                .where((d) => (d.data()?['role'] ?? '') == 'Consultante')
                                .toList();
                            if (ps.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: _InfoCard(child: Text('Cargando consultantes…')),
                              );
                            }
                            if (patients.isEmpty) return const SizedBox.shrink();

                            return _InfoCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Tus consultantes',
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  ...patients.map((d) {
                                    final m = d.data()!;
                                    final name = (m['displayName'] ??
                                            '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}')
                                        .toString()
                                        .trim();
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.person_outline,
                                              size: 18, color: Colors.black54),
                                          const SizedBox(width: 8),
                                          Expanded(
                                              child: Text(name.isEmpty ? 'Usuario' : name)),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
                        );
                      }

                      return Column(
                        children: [
                          if (myName.isNotEmpty) ...[
                            Text(
                              myName,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700, color: kInk),
                            ),
                            const SizedBox(height: 8),
                          ],
                          roleButton,
                          const SizedBox(height: 10),
                          const Text('Gestiona tu cuenta',
                              style: TextStyle(color: Colors.black54)),
                          const SizedBox(height: 14),
                          if (extra != null) extra,
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // === Botón Perfil ===
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/settings/edit-profile'),
                      icon: const Icon(Icons.person_outline),
                      label: const Text('Perfil'),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // === Botón Cerrar Sesión ===
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: kPink,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (!mounted) return;
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar Sesión'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: child,
    );
  }
}
