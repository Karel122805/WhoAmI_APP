import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../brand_logo.dart';
import '../theme.dart';
import 'home_caregiver.dart';
import 'home_consultant.dart';
import 'choice_start.dart'; // 👈 agregado para volver al inicio si no hay stack

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static const route = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePass = true;

  static const String _kLastResetTsKey = 'last_reset_email_at';
  static const Duration _resetCooldown = Duration(seconds: 60);
  DateTime? _lastResetEmailAt;

  Timer? _resetTimer;
  int _resetSecondsLeft = 0;
  Timer? _pulseTimer;
  bool _pulseUp = false;
  static const int _pulseThreshold = 10;

  final GlobalKey<_ShakeWidgetState> _passShakeKey =
      GlobalKey<_ShakeWidgetState>();
  bool _passwordError = false;
  String? _passwordErrorText;

  @override
  void initState() {
    super.initState();
    _loadCooldowns().then((_) => _startResetCountdownIfNeeded());
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _pulseTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCooldowns() async {
    final prefs = await SharedPreferences.getInstance();
    final resMs = prefs.getInt(_kLastResetTsKey);
    if (resMs != null) {
      _lastResetEmailAt = DateTime.fromMillisecondsSinceEpoch(resMs);
    }
  }

  Future<void> _saveResetTs(DateTime when) async {
    _lastResetEmailAt = when;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastResetTsKey, when.millisecondsSinceEpoch);
  }

  void _startResetCountdownIfNeeded() {
    _resetTimer?.cancel();
    final now = DateTime.now();
    if (_lastResetEmailAt == null) {
      _resetSecondsLeft = 0;
      _stopPulse();
      setState(() {});
      return;
    }
    final elapsed = now.difference(_lastResetEmailAt!);
    final remaining = _resetCooldown - elapsed;
    _resetSecondsLeft = remaining.isNegative ? 0 : remaining.inSeconds;
    _updatePulseState();
    setState(() {});
    if (_resetSecondsLeft > 0) {
      _resetTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        if (_resetSecondsLeft <= 1) {
          t.cancel();
          _resetSecondsLeft = 0;
          _stopPulse();
          setState(() {});
        } else {
          _resetSecondsLeft -= 1;
          _updatePulseState();
          setState(() {});
        }
      });
    }
  }

  void _updatePulseState() {
    if (_resetSecondsLeft > 0 && _resetSecondsLeft <= _pulseThreshold) {
      _startPulse();
    } else {
      _stopPulse();
    }
  }

  void _startPulse() {
    if (_pulseTimer != null) return;
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!mounted) return;
      _pulseUp = !_pulseUp;
      setState(() {});
    });
  }

  void _stopPulse() {
    _pulseTimer?.cancel();
    _pulseTimer = null;
    _pulseUp = false;
  }

  Future<void> _ensureUserProfile(User user) async {
    final db = FirebaseFirestore.instance;
    final ref = db.collection('users').doc(user.uid);
    final snap = await ref.get();
    final m = snap.data() ?? <String, dynamic>{};

    final firstName = ((m['firstName'] ?? '') as String).trim();
    final lastName = ((m['lastName'] ?? '') as String).trim();

    String display = ((m['displayName'] ?? '') as String).trim();
    if (display.isEmpty) {
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        display = '$firstName $lastName'.trim();
      } else {
        display =
            (user.displayName ?? user.email?.split('@').first ?? 'Usuario')
                .trim();
      }
    }

    final payload = <String, dynamic>{
      'email': (user.email ?? '').toLowerCase(),
      'firstName': firstName,
      'lastName': lastName,
      'displayName': display,
      'displayNameLower': display.toLowerCase(),
      'role': (m['role'] ?? ''),
      'updatedAt': FieldValue.serverTimestamp(),
      if (!snap.exists) 'createdAt': FieldValue.serverTimestamp(),
    };

    await ref.set(payload, SetOptions(merge: true));
  }

  String? _emailRule(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Requerido';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s);
    return ok ? null : 'Ingresa un correo válido';
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Future<void> _sendPasswordReset() async {
    String email = _email.text.trim().toLowerCase();
    if (email.isEmpty) {
      _showErrorSnack('Escribe tu correo para recuperar tu contraseña.');
      return;
    }

    final now = DateTime.now();
    final canSend = _lastResetEmailAt == null ||
        now.difference(_lastResetEmailAt!) >= _resetCooldown;

    if (!canSend) {
      final remaining = _resetCooldown - now.difference(_lastResetEmailAt!);
      final secondsLeft = remaining.isNegative ? 0 : remaining.inSeconds;
      _showErrorSnack('Intenta de nuevo en ~${secondsLeft}s.');
      _startResetCountdownIfNeeded();
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      await _saveResetTs(now);
      _startResetCountdownIfNeeded();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enlace enviado a $email'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorSnack('No se pudo enviar el correo: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _passwordError = false;
      _passwordErrorText = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim().toLowerCase(),
        password: _pass.text,
      );

      final user = FirebaseAuth.instance.currentUser!;
      await _ensureUserProfile(user);

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = snap.data() ?? {};
      final role = (data['role'] as String?)?.trim();
      final name =
          '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim().isEmpty
              ? (user.email?.split('@').first ?? 'Usuario')
              : '${data['firstName']} ${data['lastName']}';

      if (!mounted) return;

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
        _showErrorSnack('Tu cuenta no tiene rol asignado.');
      }
    } on FirebaseAuthException {
      _showErrorSnack('Correo o contraseña incorrecta.');
      setState(() {
        _passwordError = true;
        _passwordErrorText = 'Correo o contraseña incorrecta.';
      });
      _pass.clear();
      _passShakeKey.currentState?.shake();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resetLabel = _resetSecondsLeft > 0
        ? '¿Olvidaste tu contraseña? (${_resetSecondsLeft}s)'
        : '¿Olvidaste tu contraseña?';

    final pulseScale = (_resetSecondsLeft > 0 &&
            _resetSecondsLeft <= _pulseThreshold &&
            _pulseUp)
        ? 1.06
        : 1.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kInk),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                  context, ChoiceStart.route, (_) => false);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 24),
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
                    ShakeWidget(
                      key: _passShakeKey,
                      child: TextFormField(
                        controller: _pass,
                        obscureText: _obscurePass,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requerido' : null,
                        onChanged: (_) {
                          if (_passwordError) {
                            setState(() {
                              _passwordError = false;
                              _passwordErrorText = null;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          errorText: _passwordError ? _passwordErrorText : null,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey[700],
                            ),
                            onPressed: () {
                              setState(() => _obscurePass = !_obscurePass);
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedScale(
                        scale: pulseScale,
                        duration: const Duration(milliseconds: 300),
                        child: TextButton(
                          style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6A1B9A)),
                          onPressed: _resetSecondsLeft > 0
                              ? null
                              : _sendPasswordReset,
                          child: Text(resetLabel),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      child: SizedBox(
                        width: 296,
                        height: 56,
                        child: FilledButton(
                          style: pillLav(),
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(),
                                )
                              : const Text('Entrar'),
                        ),
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
        ),
      );
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({
    required this.controller,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.keyboardType,
  });
  final TextEditingController controller;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      validator: validator,
      decoration: const InputDecoration(border: OutlineInputBorder()),
    );
  }
}

/// ============ ShakeWidget ============
class ShakeWidget extends StatefulWidget {
  const ShakeWidget({
    super.key,
    required this.child,
    this.magnitude = 10,
    this.duration = const Duration(milliseconds: 420),
  });
  final Widget child;
  final double magnitude;
  final Duration duration;
  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  Future<void> shake() async {
    if (!mounted) return;
    await _controller.forward(from: 0);
    if (!mounted) return;
    _controller.reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        final t = _anim.value;
        final dx =
            math.sin(t * 3 * 2 * math.pi) * widget.magnitude * (1.0 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
