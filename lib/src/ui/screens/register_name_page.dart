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
  final _nombre = TextEditingController();
  final _apellidos = TextEditingController();
  DateTime? _birthday;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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

                      const _FieldLabel('Nombre'),
                      const SizedBox(height: 6),
                      TextField(controller: _nombre, decoration: const InputDecoration(hintText: '')),

                      const SizedBox(height: 14),
                      const _FieldLabel('Apellidos'),
                      const SizedBox(height: 6),
                      TextField(controller: _apellidos, decoration: const InputDecoration(hintText: '')),

                      const SizedBox(height: 14),
                      const _FieldLabel('Fecha de nacimiento'),
                      const SizedBox(height: 6),
                      _DateBox(
                        valueText: _birthday == null ? '' : _fmt(_birthday!),
                        onTap: () async {
                          final now = DateTime.now();
                          final initial = _birthday ?? DateTime(now.year - 18, now.month, now.day);
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: DateTime(1900),
                            lastDate: now,
                          );
                          if (picked != null) setState(() => _birthday = picked);
                        },
                      ),

                      const SizedBox(height: 28),
                      Align(
                        child: SizedBox(
                          width: 296, height: 56,
                          child: FilledButton(
                            style: pillBlue(),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                RegisterPasswordPage.route,
                                arguments: {
                                  'nombre': _nombre.text.trim(),
                                  'apellidos': _apellidos.text.trim(),
                                  'birthday': _birthday?.toIso8601String(),
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

class _DateBox extends StatelessWidget {
  const _DateBox({required this.valueText, required this.onTap});
  final String valueText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, behavior: HitTestBehavior.opaque,
      child: InputDecorator(
        decoration: const InputDecoration(hintText: ''),
        child: Text(valueText),
      ),
    );
  }
}
