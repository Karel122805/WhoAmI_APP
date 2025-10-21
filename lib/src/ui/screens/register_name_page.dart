// lib/src/ui/screens/register_name_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // 👇 controlador visible con slashes automáticos
  final _dobCtrl = TextEditingController();

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

  // Intenta parsear "dd/MM/yyyy" a DateTime
  DateTime? _parseDob(String s) {
    final p = s.split('/');
    if (p.length != 3) return null;
    final d = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final y = int.tryParse(p[2]);
    if (d == null || m == null || y == null) return null;
    try {
      final dt = DateTime(y, m, d);
      // valida que no haya autocorrección (p.ej., 32 -> 01 del siguiente mes)
      if (dt.day == d && dt.month == m && dt.year == y) return dt;
    } catch (_) {}
    return null;
  }

  void _onDobChanged(String _) {
    final dt = _parseDob(_dobCtrl.text);
    setState(() {
      _birthday = dt;
      _birthdayError = null; // limpiar mientras escribe
    });
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('es', 'MX'),
      initialDate: _birthday ?? _adultCutoff,
      firstDate: DateTime(1900),
      lastDate: _adultCutoff,
      helpText: 'Selecciona tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      initialEntryMode: DatePickerEntryMode.calendarOnly, // calendario sin caja interna
    );
    if (picked != null) {
      setState(() {
        _birthday = DateTime(picked.year, picked.month, picked.day);
        _dobCtrl.text = _fmt(_birthday!);
        _birthdayError = null;
      });
    }
  }

  void _next() {
    final validForm = _formKey.currentState!.validate();

    // valida DOB
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
  void dispose() {
    _nombre.dispose();
    _apellidos.dispose();
    _dobCtrl.dispose();
    super.dispose();
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

                        // ===== Campo Nombre =====
                        const _FieldLabel('Nombre'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nombre,
                          decoration: const InputDecoration(hintText: ''),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
                        ),

                        const SizedBox(height: 14),

                        // ===== Campo Apellidos =====
                        const _FieldLabel('Apellidos'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _apellidos,
                          decoration: const InputDecoration(hintText: ''),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Los apellidos son obligatorios' : null,
                        ),

                        const SizedBox(height: 14),

                        // ===== Fecha de nacimiento =====
                        const _FieldLabel('Fecha de nacimiento'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _dobCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: _onDobChanged,
                          // 👇 OJO: sin `const` para evitar el error.
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(8), // 8 dígitos (ddMMyyyy)
                            _DateSlashFormatter(),                // inserta “/”
                          ],
                          decoration: InputDecoration(
                            hintText: 'dd/mm/aaaa',
                            suffixIcon: IconButton(
                              tooltip: 'Elegir en calendario',
                              icon: const Icon(Icons.calendar_today),
                              onPressed: _pickDob,
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

                        // ===== Botón Siguiente =====
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
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: kInk,
        ),
      );
}

/// Inserta "/" automáticamente al escribir una fecha dd/MM/aaaa.
/// Tecleo: 1 2 0 9 2 0 0 5  ->  12/09/2005
class _DateSlashFormatter extends TextInputFormatter {
  const _DateSlashFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Solo dígitos
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 8) digits = digits.substring(0, 8); // ddMMyyyy

    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buf.write(digits[i]);
      if (i == 1 || i == 3) buf.write('/');
    }

    final formatted = buf.toString();

    // Cursor al final del texto formateado
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
