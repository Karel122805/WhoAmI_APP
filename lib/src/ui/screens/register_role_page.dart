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

  Future<void> _finishSignUp(String role) async {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final email    = (args['email'] as String?)?.trim();
    final password = args['password'] as String?;
    final nombre   = (args['nombre'] as String?)?.trim();
    final apellidos= (args['apellidos'] as String?)?.trim();
    final birthdayIso = args['birthday'] as String?;
    final birthday = birthdayIso != null ? DateTime.tryParse(birthdayIso) : null;

    if (email == null || password == null || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faltan correo o contraseña.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = cred.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'firstName': nombre,
        'lastName': apellidos,
        'birthday': birthday != null ? Timestamp.fromDate(birthday) : null,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await cred.user!.updateDisplayName(
        [nombre, apellidos].where((e) => (e ?? '').isNotEmpty).join(' '),
      );

      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Cuenta creada'),
            content: const Text('Tu cuenta se creó correctamente.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Aceptar'))],
          ),
        );
      }

      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, LoginPage.route, (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Ocurrió un problema.';
      if (e.code == 'email-already-in-use') msg = 'Ese correo ya está en uso.';
      else if (e.code == 'invalid-email')   msg = 'Correo inválido.';
      else if (e.code == 'weak-password')   msg = 'La contraseña es muy débil.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                                onPressed: _saving ? null : () => Navigator.maybePop(context),
                                icon: const Icon(Icons.arrow_back, color: kInk),
                              ),
                            ),
                            const Center(
                              child: Text('Regístrate',
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kInk)),
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
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kInk),
                      ),
                      const SizedBox(height: 24),

                      Align(
                        child: SizedBox(
                          width: 296, height: 56,
                          child: FilledButton(
                            style: pillLav(),
                            onPressed: _saving ? null : () => _finishSignUp('Cuidador'),
                            child: _saving
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator())
                              : const Text('Cuidador'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(child: Text('O', style: TextStyle(fontSize: 18, color: kInk))),
                      const SizedBox(height: 16),
                      Align(
                        child: SizedBox(
                          width: 296, height: 56,
                          child: FilledButton(
                            style: pillBlue(),
                            onPressed: _saving ? null : () => _finishSignUp('Consultante'),
                            child: _saving
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator())
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
