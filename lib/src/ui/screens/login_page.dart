// lib/src/ui/screens/login_page.dart
import 'dart:async'; // 👈 Timer para cuenta regresiva y pulso
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../brand_logo.dart';
import '../theme.dart';
import 'home_caregiver.dart';
import 'home_consultant.dart';

// 👇 agrega / reemplaza
import 'package:whoami_app/services/biometric_auth_service.dart';
import 'package:whoami_app/src/ui/screens/lock_screen.dart';
import 'package:whoami_app/src/ui/screens/home_router.dart';

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

  // ⏱️ Cooldown persistente: verificación de correo
  static const String _kLastVerificationTsKey = 'last_verification_email_at';
  static const Duration _verificationCooldown = Duration(seconds: 60);
  DateTime? _lastVerificationEmailAt;

  // ⏱️ Cooldown persistente: reset de contraseña
  static const String _kLastResetTsKey = 'last_reset_email_at';
  static const Duration _resetCooldown = Duration(seconds: 60);
  DateTime? _lastResetEmailAt;

  // ⏱️ Cuenta regresiva visible para reset
  Timer? _resetTimer;
  int _resetSecondsLeft = 0;

  // ✨ Pulso visual cuando quedan ≤10s
  static const int _pulseThreshold = 10;
  Timer? _pulseTimer;
  bool _pulseUp = false;

  @override
  void initState() {
    super.initState();
    _loadCooldowns().then((_) {
      _startResetCountdownIfNeeded(); // inicia contador si corresponde
    });
    _maybeShowLock();
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _pulseTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCooldowns() async {
    final prefs = await SharedPreferences.getInstance();
    final verMs = prefs.getInt(_kLastVerificationTsKey);
    final resMs = prefs.getInt(_kLastResetTsKey);
    if (verMs != null) _lastVerificationEmailAt = DateTime.fromMillisecondsSinceEpoch(verMs);
    if (resMs != null) _lastResetEmailAt = DateTime.fromMillisecondsSinceEpoch(resMs);
  }

  Future<void> _saveVerificationTs(DateTime when) async {
    _lastVerificationEmailAt = when;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastVerificationTsKey, when.millisecondsSinceEpoch);
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
      _pulseUp = !_pulseUp; // alterna el escalado
      setState(() {});
    });
  }

  void _stopPulse() {
    _pulseTimer?.cancel();
    _pulseTimer = null;
    _pulseUp = false;
  }

  Future<void> _maybeShowLock() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      final enabled = await BiometricAuthService.instance.getAppLockEnabled();
      if (enabled && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LockScreen()),
        );
      }
    }
  }

  String? _emailRule(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Requerido';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s);
    return ok ? null : 'Ingresa un correo válido';
  }

  // =========================
  // Recuperación (con AlertDialog)
  // =========================
  Future<String?> _promptEmailForReset() async {
    final controller = TextEditingController(text: _email.text.trim());
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            hintText: 'tucorreo@ejemplo.com',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF6A1B9A)),
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: pillLav(),
            onPressed: () {
              final value = controller.text.trim().toLowerCase();
              Navigator.pop(ctx, value.isEmpty ? null : value);
            },
            child: const Text('Enviar enlace'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPasswordReset() async {
    String email = _email.text.trim().toLowerCase();

    if (email.isEmpty) {
      final typed = await _promptEmailForReset();
      if (typed == null) return;
      email = typed.trim().toLowerCase();
    }

    // ⏱️ Cooldown para reset con contador
    final now = DateTime.now();
    final canSend = _lastResetEmailAt == null ||
        now.difference(_lastResetEmailAt!) >= _resetCooldown;

    if (!canSend) {
      final remaining = _resetCooldown - now.difference(_lastResetEmailAt!);
      final secondsLeft = remaining.isNegative ? 0 : remaining.inSeconds;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ya enviamos un enlace recientemente. Intenta de nuevo en ~${secondsLeft}s.',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
        ),
      );
      _startResetCountdownIfNeeded();
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      await _saveResetTs(now);
      _startResetCountdownIfNeeded(); // empieza contador
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Enlace enviado a $email',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
        ),
      );

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Revisa tu correo'),
          content: Text(
            'Te enviamos un enlace para restablecer tu contraseña a:\n\n$email\n\n'
            'Si no lo ves en tu bandeja de entrada, revisa también la carpeta de SPAM o Correo no deseado.',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim().toLowerCase(),
        password: _pass.text,
      );

      // 🔒 Chequeo de verificación con cooldown persistente (sin botón)
      final user = FirebaseAuth.instance.currentUser!;
      if (!user.emailVerified) {
        final now = DateTime.now();
        final canResend = _lastVerificationEmailAt == null ||
            now.difference(_lastVerificationEmailAt!) >= _verificationCooldown;

        if (canResend) {
          try {
            await user.sendEmailVerification();
            await _saveVerificationTs(now);
          } on FirebaseAuthException catch (e) {
            if (e.code != 'too-many-requests') {
              // debugPrint('sendEmailVerification error: ${e.code}');
            }
          }
        }

        await FirebaseAuth.instance.signOut();
        if (!mounted) return;

        final remaining = _lastVerificationEmailAt == null
            ? Duration.zero
            : _verificationCooldown - DateTime.now().difference(_lastVerificationEmailAt!);
        final secondsLeft = remaining.isNegative ? 0 : remaining.inSeconds;
        final extra =
            canResend ? '' : '\n\nPuedes solicitar otro envío en ~${secondsLeft}s.';

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Verifica tu correo'),
            content: Text(
              'Tu cuenta aún no está verificada.\n\n'
              '${canResend ? 'Hemos enviado (o reenviado) el enlace a:' : 'Ya enviamos un enlace recientemente a:'}\n'
              '${_email.text.trim().toLowerCase()}\n\n'
              'Abre ese correo y confirma para poder iniciar sesión. '
              'Si no lo ves, revisa SPAM.$extra',
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF6A1B9A)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              canResend
                  ? 'Te enviamos el enlace de verificación. Revisa tu correo.'
                  : 'Ya enviamos un enlace recientemente. Intenta de nuevo en ~${secondsLeft}s.',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red,
          ),
        );

        setState(() => _loading = false);
        return; // 🚫 no continúa al Home
      }

      // Biometría/PIN
      final supported = await BiometricAuthService.instance.canCheckBiometrics();
      if (supported) {
        final enable = await _askEnableQuickUnlock(context);
        await BiometricAuthService.instance.setAppLockEnabled(enable);
      } else {
        await BiometricAuthService.instance.setAppLockEnabled(false);
      }

      // Rol desde Firestore
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = snap.data() ?? {};
      final role = (data['role'] as String?)?.trim();

      final firstName = (data['firstName'] as String?)?.trim();
      final lastName  = (data['lastName'] as String?)?.trim();
      final displayFromFs =
          [firstName, lastName].where((e) => (e ?? '').isNotEmpty).join(' ');
      final name = displayFromFs.isNotEmpty
          ? displayFromFs
          : (user.displayName ?? user.email?.split('@').first ?? 'Usuario');

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tu cuenta no tiene rol asignado.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'No se pudo iniciar sesión.';
      if (e.code == 'invalid-email') msg = 'Correo inválido.';
      else if (e.code == 'user-not-found') msg = 'Usuario no encontrado.';
      else if (e.code == 'wrong-password') msg = 'Contraseña incorrecta.';
      else if (e.code == 'too-many-requests') {
        msg = 'Demasiados intentos. Espera un momento y vuelve a intentar. '
              'Si aún no verificas tu cuenta, revisa tu correo y confirma.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _askEnableQuickUnlock(BuildContext context) async {
    final agree = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Activar inicio rápido'),
        content: const Text(
          'Podrás entrar con huella, rostro o PIN del dispositivo. '
          'Si falla, siempre podrás usar tu contraseña.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF6A1B9A)),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Después'),
          ),
          FilledButton(
            style: pillLav(),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
    return agree ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Etiqueta dinámica del botón de reset
    final resetLabel = _resetSecondsLeft > 0
        ? '¿Olvidaste tu contraseña? (${_resetSecondsLeft}s)'
        : '¿Olvidaste tu contraseña?';

    // Escala de pulso (1.0 -> 1.06) si quedan ≤10s
    final pulseScale = (_resetSecondsLeft > 0 && _resetSecondsLeft <= _pulseThreshold && _pulseUp)
        ? 1.06
        : 1.0;

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

                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: AnimatedScale(
                            scale: pulseScale,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF6A1B9A),
                              ),
                              onPressed: _resetSecondsLeft > 0 ? null : _sendPasswordReset,
                              child: Text(resetLabel),
                            ),
                          ),
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
                                      child: CircularProgressIndicator(),
                                    )
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
