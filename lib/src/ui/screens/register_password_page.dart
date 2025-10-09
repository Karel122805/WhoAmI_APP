// lib/src/ui/screens/register_password_page.dart
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
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ======= Estado del indicador de seguridad =======
  int _passScore = 0;             // 0..5
  String _passLabel = 'Vacía';    // etiqueta visible
  Color _passColor = Colors.grey; // color de la barra/etiqueta

  // ---------- Reglas ----------
  String? _emailRule(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Requerido';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s);
    return ok ? null : 'Ingresa un correo válido';
  }

  String? _passRule(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Requerido';
    if (s.length < 8) return 'Debe tener mínimo 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(s)) return 'Debe incluir al menos una mayúscula';
    if (!RegExp(r'[a-z]').hasMatch(s)) return 'Debe incluir al menos una letra minúscula';
    if (!RegExp(r'[0-9]').hasMatch(s)) return 'Debe incluir al menos un número';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(s)) {
      return 'Debe incluir al menos un símbolo o carácter especial';
    }
    return null;
  }

  // ---------- Cálculo de seguridad ----------
  void _updatePasswordStrength(String s) {
    final score = _passwordScore(s);
    setState(() {
      _passScore = score;
      _passLabel = _passwordLabel(score);
      _passColor = _passwordColor(score);
    });
  }

  int _passwordScore(String s) {
    if (s.isEmpty) return 0;
    int score = 0;
    if (RegExp(r'[A-Z]').hasMatch(s)) score++;          // mayúscula
    if (RegExp(r'[a-z]').hasMatch(s)) score++;          // minúscula
    if (RegExp(r'[0-9]').hasMatch(s)) score++;          // número
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(s)) score++; // símbolo
    if (s.length >= 12) score++;                        // bonus por longitud
    // score final 0..5
    return score;
  }

  String _passwordLabel(int score) {
    switch (score) {
      case 0: return 'Vacía';
      case 1: return 'Débil';
      case 2: return 'Media';
      case 3: return 'Fuerte';
      case 4: return 'Muy fuerte';
      case 5: return 'Excelente';
      default: return 'Vacía';
    }
  }

  Color _passwordColor(int score) {
    switch (score) {
      case 0: return Colors.grey;
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.amber;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green;
      default: return Colors.grey;
    }
  }

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
                                left: 0,
                                top: 8,
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
                          onChanged: _updatePasswordStrength, // 👈 actualiza indicador en vivo
                        ),

                        // Indicador de seguridad
                        const SizedBox(height: 10),
                        _PasswordStrengthBar(
                          score: _passScore,
                          color: _passColor,
                          label: _passLabel,
                        ),

                        const SizedBox(height: 10),
                        const Text(
                          'Debe tener al menos 8 caracteres, incluir letras, una mayúscula, números y un símbolo.',
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
                            width: 296,
                            height: 56,
                            child: FilledButton(
                              style: pillBlue(),
                              onPressed: () {
                                if (!_formKey.currentState!.validate()) return;
                                Navigator.pushNamed(
                                  context,
                                  RegisterRolePage.route,
                                  arguments: {
                                    ...prev,
                                    'email': _email.text.trim().toLowerCase(),
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
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk),
      );
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({
    required this.controller,
    this.obscure = false,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final bool obscure;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;

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
      onChanged: onChanged,
      decoration: const InputDecoration(hintText: ''),
      style: const TextStyle(fontSize: 16, color: kInk),
    );
  }
}

// ====== Barra de fuerza de contraseña ======
class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({
    required this.score,
    required this.color,
    required this.label,
  });

  final int score;   // 0..5
  final Color color; // dinámico
  final String label;

  @override
  Widget build(BuildContext context) {
    final value = (score.clamp(0, 5)) / 5.0;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value == 0 ? 0.02 : value, // una rayita visible si está vacío
              minHeight: 10,
              backgroundColor: const Color(0xFFEAEAEA),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
