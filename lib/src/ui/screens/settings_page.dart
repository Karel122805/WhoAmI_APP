import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/patients_service.dart';

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

  // Paleta base
  static const Color kPurple = Color(0xFFD6A7F4);
  static const Color kBlue = Color(0xFF9ED3FF);
  static const Color kPink = Color(0xFFFFB3B3);
  static const Color kInk = Color(0xFF111111);

  // Tonos verdes (Casa Coyotes)
  static const Color verdeOscuro = Color(0xFF234B2C);
  static const Color verdeMedio = Color(0xFF32693B);
  static const Color verdeClaro = Color(0xFFEAF3EC);

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
          style: TextStyle(color: kInk, fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              // Menos padding superior para subir los componentes
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Información del usuario y rol
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _db.collection('users').doc(_uid).snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(),
                        );
                      }

                      final me = snap.data?.data() ?? {};
                      final role = (me['role'] as String?)?.trim() ?? '';
                      final firstName = (me['firstName'] as String?)?.trim() ?? '';
                      final lastName = (me['lastName'] as String?)?.trim() ?? '';
                      final myName = [firstName, lastName].where((e) => e.isNotEmpty).join(' ');
                      final caregiverId = me['caregiverId'] as String?;

                      // Colores base para roles
                      final roleColor =
                          role == 'Cuidador' ? const Color(0xFFBE83F0) : const Color(0xFF6BB5F5);
                      final roleBg =
                          role == 'Cuidador' ? const Color(0xFFF5E9FC) : const Color(0xFFE8F5FF);

                      // Etiqueta de rol, con bordes menos curvos
                      final roleTag = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: roleBg,
                          border: Border.all(color: roleColor, width: 1.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          role.isEmpty ? 'Sin rol' : role,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: roleColor,
                            fontSize: 16,
                            letterSpacing: 0.2,
                          ),
                        ),
                      );

                      // Sección adicional según el rol, ubicada inmediatamente debajo del rol
                      Widget? roleSection;

                      // Si es Consultante, mostrar su cuidador (fondo morado muy claro, texto morado)
                      if (role == 'Consultante') {
                        if (caregiverId != null && caregiverId.isNotEmpty) {
                          roleSection = FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            future: _db.collection('users').doc(caregiverId).get(),
                            builder: (context, cs) {
                              if (cs.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 8),
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

                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(top: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5E9FC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFBE83F0), width: 1.6),
                                ),
                                child: Text(
                                  'Tu cuidador: $name',
                                  style: const TextStyle(
                                    color: Color(0xFFBE83F0),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          );
                        }
                      }

                      // Si es Cuidador, mostrar sus consultantes (fondo azul muy claro, textos azules)
                      else if (role == 'Cuidador') {
                        roleSection = StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
                          stream: _svc.streamPatientsOfCaregiver(_uid),
                          builder: (context, ps) {
                            final patients = (ps.data ?? [])
                                .where((d) => (d.data()?['role'] ?? '') == 'Consultante')
                                .toList();
                            if (ps.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: _InfoCard(child: Text('Cargando consultantes…')),
                              );
                            }
                            if (patients.isEmpty) return const SizedBox.shrink();

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(top: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF6BB5F5), width: 1.6),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tus consultantes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6BB5F5),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...patients.map((d) {
                                    final m = d.data()!;
                                    final name = (m['displayName'] ??
                                            '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}')
                                        .toString()
                                        .trim();
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.person_outline,
                                              size: 18, color: Color(0xFF6BB5F5)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              name.isEmpty ? 'Usuario' : name,
                                              style: const TextStyle(color: Color(0xFF6BB5F5)),
                                            ),
                                          ),
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

                      // Construcción visual superior, con todo más arriba
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (myName.isNotEmpty)
                            Text(
                              myName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: kInk,
                              ),
                            ),
                          const SizedBox(height: 6),
                          roleTag,
                          if (roleSection != null) ...[
                            roleSection,
                            const SizedBox(height: 16),
                          ],
                          // "Gestiona tu cuenta" se mueve debajo de las tarjetas
                          const Text(
                            'Gestiona tu cuenta',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    },
                  ),

                  // Botón Perfil
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/settings/edit-profile'),
                      icon: const Icon(Icons.person_outline),
                      label: const Text('Perfil'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Botón Cerrar Sesión
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: kPink,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
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

// Tarjeta genérica
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: child,
    );
  }
}
