import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  static const route = '/settings/edit-profile';

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Controllers
  final _firstName = TextEditingController();
  final _lastName  = TextEditingController();
  final _email     = TextEditingController();
  final _dobCtrl   = TextEditingController(); // dd/mm/aaaa

  // Estado
  bool _loading = true;
  bool _saving  = false;
  bool _dirty   = false;
  bool _isCaregiver = false; // habilita edición de nombre/apellidos/fecha

  // Datos
  DateTime? _birthDate;
  String? _photoUrl;
  File? _localPhoto;

  // Originales para restaurar/cotejar
  late Map<String, String?> _original; // birthDate en ISO-8601

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Lee datos del usuario (Auth + Firestore) y popula la UI
  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser!;
    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = snap.data() ?? {};

    _firstName.text = (data['firstName'] as String?) ?? '';
    _lastName.text  = (data['lastName']  as String?) ?? '';
    _email.text     = user.email ?? '';
    _photoUrl       = user.photoURL;

    // rol
    final role = (data['role'] as String?)?.trim() ?? 'Consultante';
    _isCaregiver = role == 'Cuidador';

    // fecha de nacimiento desde distintos formatos/campos
    final rawDob = data['birthDate'] ?? data['birthday'] ?? data['dob'] ?? data['dateOfBirth'];
    _birthDate = _parseBirthDate(rawDob);
    _dobCtrl.text = _birthDate == null ? '' : _fmt(_birthDate!);

    _original = {
      'firstName': _firstName.text,
      'lastName' : _lastName.text,
      'email'    : _email.text,
      'photo'    : _photoUrl,
      'birthDate': _birthDate?.toIso8601String(),
    };

    // Escuchar cambios de texto solo si Cuidador
    if (_isCaregiver) {
      for (final c in [_firstName, _lastName, _dobCtrl]) {
        c.addListener(_recomputeDirty);
      }
    }

    _localPhoto = null;
    _dirty = false;

    if (mounted) setState(() => _loading = false);
  }

  // ===== Helpers =====
  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  DateTime? _parseBirthDate(dynamic raw) {
    if (raw == null) return null;
    try {
      if (raw is Timestamp) return raw.toDate();
    } catch (_) {}
    if (raw is int) {
      try { return DateTime.fromMillisecondsSinceEpoch(raw); } catch (_) {}
    }
    if (raw is String) {
      try { return DateTime.parse(raw); } catch (_) {
        final p = raw.split('/');
        if (p.length == 3) {
          final d = int.tryParse(p[0]);
          final m = int.tryParse(p[1]);
          final y = int.tryParse(p[2]);
          if (d != null && m != null && y != null) return DateTime(y, m, d);
        }
      }
    }
    return null;
  }

  void _recomputeDirty() {
    final photoChanged = _localPhoto != null;
    if (_isCaregiver) {
      final birthIso = _birthDate?.toIso8601String();
      final textChanged =
          _firstName.text != (_original['firstName'] ?? '') ||
          _lastName.text  != (_original['lastName']  ?? '') ||
          birthIso        != (_original['birthDate']);
      final newDirty = textChanged || photoChanged;
      if (newDirty != _dirty) setState(() => _dirty = newDirty);
    } else {
      final newDirty = photoChanged;
      if (newDirty != _dirty) setState(() => _dirty = newDirty);
    }
  }

  Future<void> _pickPhoto() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) {
      setState(() => _localPhoto = File(img.path));
      _recomputeDirty();
    }
  }

  Future<void> _pickBirthDate() async {
    if (!_isCaregiver) return;
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      locale: const Locale('es'),
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      helpText: 'Selecciona tu fecha de nacimiento',
    );
    if (picked != null) {
      setState(() {
        _birthDate = DateTime(picked.year, picked.month, picked.day);
        _dobCtrl.text = _fmt(_birthDate!);
      });
      _recomputeDirty();
    }
  }

  /// Subida ROBUSTA de imagen a Storage: evita `object-not-found`
  Future<String?> _uploadPhoto(User user) async {
    if (_localPhoto == null) return _photoUrl;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('avatar.jpg');

      final task = await ref.putFile(
        _localPhoto!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      if (task.state == TaskState.success) {
        final url = await ref.getDownloadURL();
        return url;
      } else {
        debugPrint('⚠️ Subida no exitosa: ${task.state}');
        return _photoUrl;
      }
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        debugPrint('❌ Storage: object-not-found en ${user.uid}/avatar.jpg');
      } else {
        debugPrint('❌ Storage error: ${e.code} ${e.message}');
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ Error subiendo imagen: $e');
      rethrow;
    }
  }

  /// Guarda cambios y “resetea” la pantalla (recarga datos + limpia `_dirty`)
  Future<void> _save({bool exitAfter = false}) async {
    if (!_dirty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cambios para guardar.')),
      );
      return;
    }

    setState(() => _saving = true);
    final user = FirebaseAuth.instance.currentUser!;

    try {
      // ===== FOTO =====
      if (_localPhoto != null) {
        final url = await _uploadPhoto(user);
        if (url != null) {
          _photoUrl = url;
          await user.updatePhotoURL(url);
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'photoURL': url}, SetOptions(merge: true));
        }
      }

      // ===== DATOS (si es cuidador) =====
      if (_isCaregiver) {
        final updates = <String, dynamic>{};

        if (_firstName.text.trim() != (_original['firstName'] ?? '')) {
          updates['firstName'] = _firstName.text.trim();
        }
        if (_lastName.text.trim() != (_original['lastName'] ?? '')) {
          updates['lastName'] = _lastName.text.trim();
        }
        if (_birthDate?.toIso8601String() != _original['birthDate']) {
          updates['birthDate'] = _birthDate; // Firestore -> Timestamp
        }

        if (updates.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(updates, SetOptions(merge: true));
        }

        final newDisplayName =
            '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim();
        if (newDisplayName != ((user.displayName ?? '').trim())) {
          await user.updateDisplayName(newDisplayName);
        }
      }

      // 🔄 refresca auth y recarga los datos para “resetear” la pantalla
      await user.reload();
      await _load();          // vuelve a leer Firestore/Auth y repuebla
      _localPhoto = null;
      _dirty = false;
      if (mounted) setState(() {});

      // ✅ Snackbar verde pastel
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFB2DFDB),
          content: Text(
            'Cambios guardados exitosamente.',
            style: TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.w700),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (exitAfter && mounted) Navigator.maybePop(context);
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron guardar los cambios. (${e.code})')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron guardar los cambios. $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ===== Diálogos / Confirmaciones =====
  Future<bool> _confirmBeforeLeave() async {
    if (!_dirty) return true;

    final action = await showDialog<_LeaveAction>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tienes cambios sin guardar'),
        content: const Text('Debes elegir una opción antes de salir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _LeaveAction.keepEditing),
            child: const Text('Seguir editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _LeaveAction.discard),
            child: const Text('Cancelar cambios'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD6A7F4),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            onPressed: () => Navigator.pop(context, _LeaveAction.saveAndExit),
            child: const Text('Guardar y salir'),
          ),
        ],
      ),
    );

    switch (action) {
      case _LeaveAction.discard:
        _restoreOriginal();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios descartados.')),
        );
        return true;
      case _LeaveAction.saveAndExit:
        await _save(exitAfter: true);
        return false; // _save intenta salir
      case _LeaveAction.keepEditing:
      default:
        return false;
    }
  }

  Future<void> _confirmDiscardInline() async {
    if (!_dirty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cambios para cancelar.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar cambios'),
        content: const Text('Tienes cambios sin guardar. Debes Guardar o Cancelar antes de salir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD6A7F4),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar cambios'),
          ),
        ],
      ),
    );
    if (ok == true) {
      _restoreOriginal();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios descartados.')),
      );
    }
  }

  void _restoreOriginal() {
    _firstName.text = _original['firstName'] ?? '';
    _lastName.text  = _original['lastName']  ?? '';
    _email.text     = _original['email']     ?? '';
    _photoUrl       = _original['photo'];
    final origDob = _original['birthDate'];
    _birthDate = (origDob == null) ? null : DateTime.tryParse(origDob);
    _dobCtrl.text = _birthDate == null ? '' : _fmt(_birthDate!);
    _localPhoto = null;
    _dirty = false;
    if (mounted) setState(() {});
  }

  // 📩 Solicitar cambio de contraseña (flujo “olvidé mi contraseña”)
  Future<void> _requestPasswordReset() async {
    final email = _email.text.trim().toLowerCase();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu cuenta no tiene correo válido.')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFB2DFDB),
          content: Text(
            'Enlace enviado a $email',
            style: const TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.w700),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Revisa tu correo'),
          content: Text(
            'Te enviamos un formulario para cambiar tu contraseña a:\n\n$email\n\n'
            'Si no lo ves, revisa también SPAM.',
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF6A1B9A)),
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'No se pudo enviar el correo de recuperación.';
      if (e.code == 'invalid-email') msg = 'El correo no es válido.';
      if (e.code == 'user-not-found') msg = 'No existe una cuenta con ese correo.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmBeforeLeave,
      child: MediaQuery(
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
                                      onPressed: () async {
                                        final canLeave = await _confirmBeforeLeave();
                                        if (canLeave && mounted) Navigator.maybePop(context);
                                      },
                                      icon: const Icon(Icons.arrow_back, color: kInk),
                                    ),
                                  ),
                                  const Center(
                                    child: Text(
                                      'Perfil',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: kInk,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // FOTO (siempre editable)
                            Center(
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 52,
                                    backgroundImage: _localPhoto != null
                                        ? FileImage(_localPhoto!)
                                        : (_photoUrl != null ? NetworkImage(_photoUrl!) : null)
                                            as ImageProvider<Object>?,
                                    child: (_localPhoto == null && _photoUrl == null)
                                        ? const Icon(Icons.person, size: 48, color: Colors.white)
                                        : null,
                                    backgroundColor: Colors.black,
                                  ),
                                  Material(
                                    color: const Color(0xFFD6A7F4),
                                    shape: const CircleBorder(),
                                    elevation: 3,
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: _pickPhoto,
                                      child: const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: Icon(Icons.photo_camera_outlined, color: Colors.white, size: 22),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Campos (habilitados sólo si Cuidador)
                            TextField(
                              controller: _firstName,
                              enabled: _isCaregiver,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => _recomputeDirty(),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _lastName,
                              enabled: _isCaregiver,
                              decoration: const InputDecoration(
                                labelText: 'Apellidos',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => _recomputeDirty(),
                            ),
                            const SizedBox(height: 12),

                            // Fecha de nacimiento
                            TextField(
                              controller: _dobCtrl,
                              readOnly: true,
                              enabled: _isCaregiver,
                              decoration: const InputDecoration(
                                labelText: 'Fecha de nacimiento',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              onTap: _isCaregiver ? _pickBirthDate : null,
                            ),
                            const SizedBox(height: 12),

                            // Correo (siempre solo lectura)
                            TextField(
                              controller: _email,
                              enabled: false,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                border: OutlineInputBorder(),
                              ),
                            ),

                            const SizedBox(height: 22),
                            const Divider(),
                            const SizedBox(height: 10),

                            // Solicitar cambio de contraseña
                            SizedBox(
                              height: 52,
                              child: FilledButton.icon(
                                style: pillLav(),
                                onPressed: _requestPasswordReset,
                                icon: const Icon(Icons.lock_reset),
                                label: const Text('Solicitar cambio de contraseña'),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // Botones Guardar / Cancelar
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _dirty ? _confirmDiscardInline : null,
                                    icon: const Icon(Icons.close_rounded, color: Colors.black),
                                    label: const Text(
                                      'Cancelar',
                                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF9EA3),
                                      disabledBackgroundColor: const Color(0x55FF9EA3),
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: (_saving || !_dirty) ? null : () => _save(),
                                    icon: _saving
                                        ? const SizedBox(
                                            width: 18, height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                          )
                                        : const Icon(Icons.save_outlined, color: Colors.black),
                                    label: Text(
                                      _saving ? 'Guardando...' : 'Guardar',
                                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF9ED3FF),
                                      disabledBackgroundColor: const Color(0x559ED3FF),
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                            if (!_dirty && !_saving)
                              const Text(
                                'Modifica tus datos para habilitar Guardar y Cancelar.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
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

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }
}

enum _LeaveAction { keepEditing, discard, saveAndExit }
