// lib/src/ui/screens/register_name_page.dart
import 'package:flutter/material.dart';
import '../brand_logo.dart';
import '../theme.dart';
import 'register_password_page.dart';

class RegisterNamePage extends StatefulWidget {
  const RegisterNamePage({super.key});
  static const route = '/register/name';

  @override
  State<RegisterNamePage> createState() => _RegisterNamePageState();
}

class _RegisterNamePageState extends State<RegisterNamePage> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellidos = TextEditingController();
  DateTime? _birthday;
  String? _birthdayError;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  DateTime get _today => DateTime.now();
  DateTime get _adultCutoff => DateTime(_today.year - 18, _today.month, _today.day);

  bool _isAdult(DateTime date) {
    final t = _today;
    final age = t.year - date.year -
        ((t.month < date.month || (t.month == date.month && t.day < date.day)) ? 1 : 0);
    return age >= 18;
  }

  void _next() {
    final validForm = _formKey.currentState!.validate();

    if (_birthday == null) {
      setState(() => _birthdayError = 'La fecha de nacimiento es obligatoria');
      return;
    } else if (!_isAdult(_birthday!)) {
      setState(() => _birthdayError = 'Debes tener al menos 18 años');
      return;
    } else {
      setState(() => _birthdayError = null);
    }

    if (!validForm) return;

    Navigator.pushNamed(
      context,
      RegisterPasswordPage.route,
      arguments: {
        'nombre': _nombre.text.trim(),
        'apellidos': _apellidos.text.trim(),
        'birthday': _birthday!.toIso8601String(),
      },
    );
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

                        const _FieldLabel('Nombre'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nombre,
                          decoration: const InputDecoration(hintText: ''),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
                        ),

                        const SizedBox(height: 14),
                        const _FieldLabel('Apellidos'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _apellidos,
                          decoration: const InputDecoration(hintText: ''),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Los apellidos son obligatorios' : null,
                        ),

                        const SizedBox(height: 14),
                        const _FieldLabel('Fecha de nacimiento'),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              // Sugerimos por defecto justo 18 años atrás
                              initialDate: _birthday ?? _adultCutoff,
                              firstDate: DateTime(1900),
                              // ❗ Máximo permitido: hoy - 18 años (evita menores de 18)
                              lastDate: _adultCutoff,
                            );
                            if (picked != null) setState(() => _birthday = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(hintText: ''),
                            child: Text(
                              _birthday == null ? 'Selecciona una fecha' : _fmt(_birthday!),
                              style: TextStyle(
                                color: _birthday == null ? Colors.grey : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        if (_birthdayError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _birthdayError!,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),

                        const SizedBox(height: 28),
                        Align(
                          child: SizedBox(
                            width: 296,
                            height: 56,
                            child: FilledButton(
                              style: pillBlue(),
                              onPressed: _next,
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
