// lib/src/ui/screens/register_patient_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/patients_service.dart';
import '../brand_logo.dart';

class RegisterPatientPage extends StatefulWidget {
  const RegisterPatientPage({super.key});
  static const route = '/patients/register';

  @override
  State<RegisterPatientPage> createState() => _RegisterPatientPageState();
}

class _RegisterPatientPageState extends State<RegisterPatientPage> {
  final _searchCtrl = TextEditingController();
  late final PatientsService _svc;

  String? get caregiverId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _svc = PatientsService(FirebaseFirestore.instance);
    _searchCtrl.addListener(() => setState(() {}));

    final uid = FirebaseAuth.instance.currentUser?.uid;
    FirebaseFirestore.instance.collection('users').doc(uid).get().then((d) {
      // ignore: avoid_print
      print('[register_patient] yo: uid=$uid role=${d.data()?['role']}');
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fmtBirthday(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final yy = d.year.toString();
      return '$dd/$mm/$yy';
    }
    if (value is String && value.isNotEmpty) return value;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (caregiverId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registrar nuevo paciente')),
        body: const Center(child: Text('Inicia sesión para continuar')),
      );
    }

    final q = _searchCtrl.text;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Registrar nuevo paciente'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const SizedBox(height: 6),
                          const Align(child: BrandLogo(size: 90)),
                          const SizedBox(height: 10),

                          // ===== Buscador =====
                          TextField(
                            controller: _searchCtrl,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Buscar',
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => _searchCtrl.clear(),
                                    )
                                  : const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ===== Lista (consultantes sin cuidador) =====
                          Expanded(
                            child: StreamBuilder<
                                List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                              stream: _svc.streamUnassignedConsultants(q: q),
                              builder: (context, snap) {
                                if (snap.hasError) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'Error: ${snap.error}',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                }

                                if (snap.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                final docs = snap.data ?? [];

                                // ignore: avoid_print
                                print(
                                    '[register_patient] resultados=${docs.length} q="$q"');

                                if (docs.isEmpty) {
                                  return const Center(
                                      child: Text('Sin resultados'));
                                }

                                return ListView.separated(
                                  itemCount: docs.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, i) {
                                    final data = docs[i].data();

                                    if ((data['role'] ?? '') != 'Consultante') {
                                      return const SizedBox.shrink();
                                    }

                                    final uid = docs[i].id;
                                    final name = (data['displayName'] ??
                                            '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}')
                                        .toString()
                                        .trim();
                                    final birthday =
                                        _fmtBirthday(data['birthday']);

                                    return _PatientResultTile(
                                      name: name.isEmpty ? 'Usuario' : name,
                                      subtitle: birthday,
                                      onAdd: () async {
                                        final id = caregiverId;
                                        if (id == null) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Sesión no válida')));
                                          return;
                                        }
                                        try {
                                          await _svc.addPatientToCaregiver(
                                            caregiverId: id,
                                            patientUserId: uid,
                                          );
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Paciente agregado')));
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      e.toString())));
                                        }
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ===== Botones =====
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  icon: const Icon(Icons.save),
                                  label: const Text('Guardar'),
                                  onPressed: () => Navigator.pop(context, true),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text('Cancelar'),
                                  onPressed: () => Navigator.pop(context),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFB3B3),
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PatientResultTile extends StatelessWidget {
  const _PatientResultTile({
    required this.name,
    required this.subtitle,
    required this.onAdd,
  });

  final String name;
  final String subtitle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 4),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),

          // Botón con ancho finito para evitar constraints infinitos dentro del Row
          SizedBox(
            height: 40,
            width: 120,
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                visualDensity: VisualDensity.compact,
                backgroundColor: const Color(0xFF7ED9A5),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
