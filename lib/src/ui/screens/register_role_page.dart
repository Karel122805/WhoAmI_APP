// lib/src/ui/screens/register_role_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../brand_logo.dart';
import '../theme.dart';
import 'login_page.dart';

class RegisterRolePage extends StatefulWidget {
  const RegisterRolePage({super.key});
  static const route = '/register/role';

  @override
  State<RegisterRolePage> createState() => _RegisterRolePageState();
}

class _RegisterRolePageState extends State<RegisterRolePage> {
  bool _saving = false;

  String _buildDisplayName(String? nombre, String? apellidos, String? email) {
    final n = (nombre ?? '').trim();
    final a = (apellidos ?? '').trim();
    final byName = [n, a].where((e) => e.isNotEmpty).join(' ').trim();
    if (byName.isNotEmpty) return byName;
    return (email ?? '').trim();
  }

  /// Muestra una ventana emergente de confirmación
  Future<bool> _confirmarRol(String role) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              title: const Text(
                'Confirmar rol',
                style: TextStyle(
                  color: kInk,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: Text(
                'Estás a punto de registrarte como "$role".\n\n'
                'Una vez creada tu cuenta, no podrás cambiar este rol.\n\n'
                '¿Deseas continuar?',
                style: const TextStyle(color: kInk, fontSize: 16),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kPurple,
                    foregroundColor: kInk,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: kInk,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _finishSignUp(String role) async {
    // Primero se confirma el rol seleccionado
    final confirmado = await _confirmarRol(role);
    if (!confirmado) return;

    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final emailRaw = (args['email'] as String?)?.trim();
    final password = args['password'] as String?;
    final nombre = (args['nombre'] as String?)?.trim();
    final apellidos = (args['apellidos'] as String?)?.trim();
    final birthdayIso = args['birthday'] as String?;
    final birthday = birthdayIso != null ? DateTime.tryParse(birthdayIso) : null;

    final email = emailRaw?.toLowerCase();

    if (email == null || password == null || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faltan correo o contraseña.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // 1) Crear cuenta en Firebase Auth
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = cred.user!.uid;

      // 2) Crear documento de usuario en Firestore
      final displayName = _buildDisplayName(nombre, apellidos, email);
      final data = <String, dynamic>{
        'email': email,
        'firstName': nombre ?? '',
        'lastName': apellidos ?? '',
        'displayName': displayName,
        'displayNameLower': displayName.toLowerCase(),
        'role': role,
        'archived': false,
        'caregiverId': null,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        if (birthday != null) 'birthday': Timestamp.fromDate(birthday),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));

      // 3) Actualizar displayName en Auth
      await cred.user!.updateDisplayName(displayName);

      // 4) Enviar correo de verificación
      try {
        await cred.user!.sendEmailVerification();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo enviar el correo de verificación. $e')),
        );
      }

      // 5) Mostrar ventana de cuenta creada
      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) {
            bool _resending = false;
            return StatefulBuilder(
              builder: (ctx, setDlg) => AlertDialog(
                title: const Text('Cuenta creada'),
                content: Text(
                  'Tu cuenta se creó correctamente.\n\n'
                  'Te enviamos un correo a:\n$email\n\n'
                  'Abre el enlace de verificación para activar tu cuenta antes de iniciar sesión.',
                ),
                actions: [
                  TextButton(
                    onPressed: _resending
                        ? null
                        : () async {
                            setDlg(() => _resending = true);
                            try {
                              await cred.user!.sendEmailVerification();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Correo de verificación reenviado.')),
                                );
                              }
                            } finally {
                              if (ctx.mounted) setDlg(() => _resending = false);
                            }
                          },
                    child: _resending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Reenviar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            );
          },
        );
      }

      // 6) Cerrar sesión y volver al login
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, LoginPage.route, (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Ocurrió un problema.';
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Este correo ya está en uso. Intenta con otro.';
          break;
        case 'invalid-email':
          msg = 'El correo no es válido.';
          break;
        case 'weak-password':
          msg = 'La contraseña es muy débil.';
          break;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg,
              style:
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e',
              style:
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // Encabezado con botón de volver
                      SizedBox(
                        height: 56,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 8,
                              child: IconButton.filled(
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFEAEAEA),
                                  shape: const CircleBorder(),
                                  fixedSize: const Size(40, 40),
                                ),
                                onPressed: _saving ? null : () => Navigator.maybePop(context),
                                icon: const Icon(Icons.arrow_back, color: kInk),
                              ),
                            ),
                            const Center(
                              child: Text(
                                'Regístrate',
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
                      const SizedBox(height: 18),
                      const Align(child: BrandLogo(size: 170)),
                      const SizedBox(height: 22),

                      const Text(
                        'Selecciona un tipo\nde usuario',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: kInk),
                      ),
                      const SizedBox(height: 24),

                      // Botón para rol: Cuidador
                      Align(
                        child: SizedBox(
                          width: 296,
                          height: 56,
                          child: FilledButton(
                            style: pillLav(),
                            onPressed: _saving
                                ? null
                                : () => _finishSignUp('Cuidador'),
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(),
                                  )
                                : const Text('Cuidador'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'O',
                          style: TextStyle(fontSize: 18, color: kInk),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botón para rol: Consultante
                      Align(
                        child: SizedBox(
                          width: 296,
                          height: 56,
                          child: FilledButton(
                            style: pillBlue(),
                            onPressed: _saving
                                ? null
                                : () => _finishSignUp('Consultante'),
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(),
                                  )
                                : const Text('Consultante'),
                          ),
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
