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
  // Solo lectura
  final _firstName = TextEditingController();
  final _lastName  = TextEditingController();
  final _email     = TextEditingController();
  final _dobCtrl   = TextEditingController(); // dd/mm/aaaa

  DateTime? _birthDate;
  String? _photoUrl;
  File? _localPhoto;

  bool _loading = true;
  bool _saving  = false;
  bool _dirty   = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser!;
    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = snap.data() ?? {};

    _firstName.text = (data['firstName'] as String?) ?? '';
    _lastName.text  = (data['lastName']  as String?) ?? '';
    _email.text     = user.email ?? '';
    _photoUrl       = user.photoURL;

    // === Fecha de nacimiento: probamos varias claves y formatos ===
    dynamic rawDob = data['birthDate'] ?? data['birthday'] ?? data['dob'] ?? data['dateOfBirth'];
    _birthDate = _parseBirthDate(rawDob);

    if (_birthDate != null) {
      _dobCtrl.text = _fmt(_birthDate!);
    } else {
      _dobCtrl.text = '';
    }

    setState(() => _loading = false);
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
      try {
        // Asumimos milisegundos desde epoch
        return DateTime.fromMillisecondsSinceEpoch(raw);
      } catch (_) {}
    }
    if (raw is String) {
      // Intenta ISO-8601 (como se envió desde el registro)
      try {
        return DateTime.parse(raw);
      } catch (_) {
        // dd/MM/yyyy
        final parts = raw.split('/');
        if (parts.length == 3) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (d != null && m != null && y != null) {
            return DateTime(y, m, d);
          }
        }
      }
    }
    return null;
  }

  void _recomputeDirty() {
    final newDirty = _localPhoto != null; // 🔐 solo la foto es editable
    if (newDirty != _dirty) setState(() => _dirty = newDirty);
  }

  Future<void> _pickPhoto() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) {
      setState(() => _localPhoto = File(img.path));
      _recomputeDirty();
    }
  }

  Future<String?> _uploadPhoto(User user) async {
    if (_localPhoto == null) return _photoUrl;
    final ref = FirebaseStorage.instance.ref().child('users/${user.uid}/avatar.jpg');
    await ref.putFile(_localPhoto!);
    return await ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (!_dirty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes modificar tu foto para poder guardar.')),
      );
      return;
    }

    setState(() => _saving = true);

    final user = FirebaseAuth.instance.currentUser!;
    try {
      // Solo foto
      if (_localPhoto != null) {
        final url = await _uploadPhoto(user);
        _photoUrl = url;
        await user.updatePhotoURL(url);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'photoURL': url}, SetOptions(merge: true));
      }

      _localPhoto = null;
      _recomputeDirty();
      await user.reload();

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
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron guardar los cambios.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancel() async {
    if (!_dirty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cambios para cancelar.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar cambios'),
        content: const Text(
          '¿Deseas cancelar tus cambios? Los campos volverán a su estado original y permanecerás en esta pantalla.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD6A7F4),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: const Text('Cancelar cambios'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _localPhoto = null;
      _recomputeDirty();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios descartados.')),
      );
    }
  }

  // 📩 Solicitar cambio de contraseña (reutiliza “Olvidé mi contraseña”)
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

      // Aviso visual + diálogo
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
            'Si no lo ves en tu bandeja de entrada, revisa también SPAM.',
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
                                      if (_dirty) {
                                        await _cancel();
                                      } else {
                                        Navigator.maybePop(context);
                                      }
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

                          // FOTO DE PERFIL (único editable)
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
                                // Botón cámara morado
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

                          // Campos en solo lectura (Edad eliminado)
                          TextField(
                            controller: _firstName,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _lastName,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'Apellidos',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _dobCtrl,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'Fecha de nacimiento',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
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

                          // Botón para solicitar cambio de contraseña (flujo "olvidé mi contraseña")
                          SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              style: pillLav(), // tu estilo lavanda
                              onPressed: _requestPasswordReset,
                              icon: const Icon(Icons.lock_reset),
                              label: const Text('Solicitar cambio de contraseña'),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Botones Guardar / Cancelar (solo foto)
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _dirty ? _cancel : null,
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
                                  onPressed: (_saving || !_dirty) ? null : _save,
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
                              'Modifica tu foto para habilitar Guardar y Cancelar.',
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
