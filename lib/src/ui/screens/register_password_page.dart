import 'package:flutter/material.dart';
import '../brand_logo.dart';
import '../theme.dart';
import 'register_role_page.dart';

class RegisterPasswordPage extends StatefulWidget {
  const RegisterPasswordPage({super.key});
  static const route = '/register/password';

  @override
  State<RegisterPasswordPage> createState() => _RegisterPasswordPageState();
}

class _RegisterPasswordPageState extends State<RegisterPasswordPage> {
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  final _pass2 = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _emailRule(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Requerido';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s);
    return ok ? null : 'Ingresa un correo válido';
  }

  String? _passRule(String? v) =>
      (v == null || v.trim().length < 8) ? 'Mínimo 8 caracteres' : null;

  @override
  Widget build(BuildContext context) {
    final prev = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};

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
                                child: Text('Regístrate',
                                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kInk)),
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
                        const _FieldLabel('Crea una contraseña'),
                        const SizedBox(height: 6),
                        _FieldBox(
                          controller: _pass,
                          obscure: true,
                          textInputAction: TextInputAction.next,
                          validator: _passRule,
                        ),

                        const SizedBox(height: 6),
                        const Text(
                          'Debe tener mínimo 8 caracteres, incluir letras y números.',
                          style: TextStyle(fontSize: 12, color: kGrey1),
                          textAlign: TextAlign.left,
                        ),

                        const SizedBox(height: 10),
                        const _FieldLabel('Confirmar contraseña'),
                        const SizedBox(height: 6),
                        _FieldBox(
                          controller: _pass2,
                          obscure: true,
                          textInputAction: TextInputAction.done,
                          validator: (v) => v != _pass.text ? 'No coincide' : null,
                        ),

                        const SizedBox(height: 28),
                        Align(
                          child: SizedBox(
                            width: 296, height: 56,
                            child: FilledButton(
                              style: pillBlue(),
                              onPressed: () {
                                if (!_formKey.currentState!.validate()) return;
                                Navigator.pushNamed(
                                  context,
                                  RegisterRolePage.route,
                                  arguments: {
                                    ...prev,                       // nombre, apellidos, birthday
                                    'email': _email.text.trim(),   // correo
                                    'password': _pass.text,
                                  },
                                );
                              },
                              child: const Text('Siguiente'),
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
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk));
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
