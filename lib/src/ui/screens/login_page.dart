// lib/src/ui/screens/login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../brand_logo.dart';
import '../theme.dart';
import 'home_caregiver.dart';
import 'home_consultant.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static const route = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  String? _emailRule(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Requerido';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s);
    return ok ? null : 'Ingresa un correo válido';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      // 1) Iniciar sesión
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim().toLowerCase(),
        password: _pass.text,
      );

      // 2) Leer rol desde Firestore
      final user = FirebaseAuth.instance.currentUser!;
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = snap.data() ?? {};
      final role = (data['role'] as String?)?.trim();

      // nombre para encabezado del menú
      final firstName = (data['firstName'] as String?)?.trim();
      final lastName  = (data['lastName'] as String?)?.trim();
      final displayFromFs =
          [firstName, lastName].where((e) => (e ?? '').isNotEmpty).join(' ');
      final name = displayFromFs.isNotEmpty
          ? displayFromFs
          : (user.displayName ?? user.email?.split('@').first ?? 'Usuario');

      if (!mounted) return;

      // 3) Navegar según rol
      if (role == 'Cuidador') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          HomeCaregiverPage.route,
          (_) => false,
          arguments: {'name': name},
        );
      } else if (role == 'Consultante') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          HomeConsultantPage.route,
          (_) => false,
          arguments: {'name': name},
        );
      } else {
        // Rol no encontrado: avisa
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tu cuenta no tiene rol asignado.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'No se pudo iniciar sesión.';
      if (e.code == 'invalid-email') msg = 'Correo inválido.';
      else if (e.code == 'user-not-found') msg = 'Usuario no encontrado.';
      else if (e.code == 'wrong-password') msg = 'Contraseña incorrecta.';
      else if (e.code == 'too-many-requests') msg = 'Demasiados intentos. Intenta más tarde.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
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
                  child: Form(
                    key: _formKey,
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
                                  icon: const Icon(Icons.arrow_back, color: kInk),
                                ),
                              ),
                              const Center(
                                child: Text(
                                  'Iniciar sesión',
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

                        const _FieldLabel('Correo electrónico'),
                        const SizedBox(height: 6),
                        _FieldBox(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _emailRule,
                        ),

                        const SizedBox(height: 14),
                        const _FieldLabel('Contraseña'),
                        const SizedBox(height: 6),
                        _FieldBox(
                          controller: _pass,
                          obscure: true,
                          textInputAction: TextInputAction.done,
                          validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                        ),

                        const SizedBox(height: 28),
                        Align(
                          child: SizedBox(
                            width: 296, height: 56,
                            child: FilledButton(
                              style: pillLav(),
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator())
                                  : const Text('Iniciar sesión'),
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
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: kInk,
          height: 1.2,
        ),
      );
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({
    required this.controller,
    this.obscure = false,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final bool obscure;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      autocorrect: false,
      enableSuggestions: !obscure,
      validator: validator,
      decoration: const InputDecoration(hintText: ''),
      style: const TextStyle(fontSize: 16, color: kInk),
    );
  }
}

