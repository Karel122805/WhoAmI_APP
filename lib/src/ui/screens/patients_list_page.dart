// lib/src/ui/screens/patients_list_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/patients_service.dart';
import 'register_patient_page.dart';

class PatientsListPage extends StatefulWidget {
  const PatientsListPage({super.key});
  static const route = '/patients/list';

  @override
  State<PatientsListPage> createState() => _PatientsListPageState();
}

class _PatientsListPageState extends State<PatientsListPage> {
  final _searchCtrl = TextEditingController();
  late final PatientsService _svc;

  String get caregiverId => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _svc = PatientsService(FirebaseFirestore.instance);
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchCtrl.text.trim().toLowerCase();

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Lista de pacientes'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ===== Buscador + botón (+) =====
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Buscar',
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => _searchCtrl.clear(),
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filled(
                          onPressed: () async {
                            // Navegación segura: SIN genérico <bool>
                            final result = await Navigator.pushNamed(
                              context,
                              RegisterPatientPage.route,
                            );
                            if (result == true && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Paciente agregado')),
                              );
                              setState(() {}); // por si volvimos muy rápido
                            }
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ===== Lista de pacientes del cuidador =====
                    Expanded(
                      child: StreamBuilder<
                          List<DocumentSnapshot<Map<String, dynamic>>>>(
                        stream: _svc.streamPatientsOfCaregiver(caregiverId),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snap.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text('Error: ${snap.error}'),
                              ),
                            );
                          }

                          var docs = (snap.data ?? [])
                              // solo consultantes
                              .where((d) => (d.data()?['role'] ?? '') == 'Consultante')
                              .toList();

                          // ordenar por nombre
                          docs.sort((a, b) {
                            String n(DocumentSnapshot<Map<String, dynamic>> x) {
                              final m = x.data() ?? {};
                              return (m['displayName'] ??
                                      '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}')
                                  .toString()
                                  .toLowerCase()
                                  .trim();
                            }
                            return n(a).compareTo(n(b));
                          });

                          // filtro por texto
                          if (q.isNotEmpty) {
                            docs = docs.where((d) {
                              final data = d.data() ?? {};
                              final name = ((data['displayName'] ??
                                      '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}')
                                  .toString()
                                  .toLowerCase());
                              return name.contains(q);
                            }).toList();
                          }

                          if (docs.isEmpty) {
                            return const Center(child: Text('Sin pacientes'));
                          }

                          return ListView.separated(
                            itemCount: docs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final data = docs[i].data()!;
                              final patientId = docs[i].id;
                              final name = (data['displayName'] ??
                                      '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}')
                                  .toString()
                                  .trim();
                              final birthday = _fmtBirthday(data['birthday']);

                              return _PatientRow(
                                name: name.isEmpty ? 'Usuario' : name,
                                subtitle: birthday,
                                onRemove: () async {
                                  // Confirmación
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Desvincular paciente'),
                                      content: Text(
                                        '¿Quitar a "$name" de tu lista?\n'
                                        'Podrás vincularlo de nuevo después.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Desvincular'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok != true) return;

                                  try {
                                    await _svc.removePatientFromCaregiver(
                                      caregiverId: caregiverId,
                                      patientUserId: patientId,
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Se quitó a "$name".')),
                                      );
                                    }
                                    // El stream se actualizará solo.
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
}

class _PatientRow extends StatefulWidget {
  const _PatientRow({
    required this.name,
    required this.subtitle,
    required this.onRemove,
  });

  final String name;
  final String subtitle;
  final Future<void> Function() onRemove;

  @override
  State<_PatientRow> createState() => _PatientRowState();
}

class _PatientRowState extends State<_PatientRow> {
  bool _busy = false;

  Future<void> _handleRemove() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onRemove();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
                Text(widget.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                if (widget.subtitle.isNotEmpty)
                  Text(widget.subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            width: 140,
            child: FilledButton.icon(
              onPressed: _busy ? null : _handleRemove,
              icon: _busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.link_off),
              label: Text(_busy ? 'Quitando…' : 'Desvincular'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFB3B3), // Rosa Figma
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
