// lib/ui/screens/calendar_page.dart
//
// Pantalla de calendario para crear y editar “recuerdos” por día.
// - Muestra un calendario (TableCalendar) con paleta de colores del tema.
// - Impide seleccionar días futuros.
// - Al seleccionar un día: si existe un recuerdo pregunta si deseas modificarlo;
//   si no existe, pregunta si deseas crear uno.
// - El contenido de la pantalla es desplazable (calendario + tarjeta del recuerdo).
// - La tarjeta del recuerdo muestra texto, imagen (si existe), y acciones.
//
// Dependencias: table_calendar, firebase_auth, firebase_storage,
// cloud_firestore, image_picker, intl

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../theme.dart'; // Paleta y estilos centralizados

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, dynamic>? _selectedMemory;

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);
  bool _isFutureDay(DateTime day) =>
      _onlyDate(day).isAfter(_onlyDate(DateTime.now()));

  @override
  void initState() {
    super.initState();
    final today = _onlyDate(DateTime.now());
    _focusedDay = today;
    _selectedDay = today;
    initializeDateFormatting('es_ES');
  }

  String _formatDateEs(DateTime d) =>
      DateFormat("d 'de' MMMM 'de' y", 'es_ES').format(d);

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: InteractiveViewer(
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  void _showDialog(String title, String message, {bool success = true}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              color: success ? kGreenPastel : Colors.red.shade400,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: kInk,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: kInk, fontSize: 15, height: 1.3),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              minimumSize: const Size.fromHeight(44),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Aceptar',
              style: TextStyle(color: kInk, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDialog(String title, String message) async {
    const Color softRed = Color(0xFFFF8A8A);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            color: kInk,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: kInk, fontSize: 15, height: 1.3),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        actions: [
          Column(
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: softRed,
                  shape: const StadiumBorder(),
                  minimumSize: const Size.fromHeight(48),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: kInk,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kBlue,
                  shape: const StadiumBorder(),
                  minimumSize: const Size.fromHeight(48),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Confirmar',
                  style: TextStyle(
                    color: kInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _loadMemory(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final dateId =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final doc = await FirebaseFirestore.instance
        .collection('memories')
        .doc(userId)
        .collection('user_memories')
        .doc(dateId)
        .get();

    setState(() {
      _selectedMemory = doc.exists ? doc.data() : null;
    });
  }

  void _openMemoryDialog(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final TextEditingController textCtrl =
        TextEditingController(text: _selectedMemory?['text'] ?? '');
    File? selectedImage;
    bool isSaving = false;

    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            padding: EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 60,
                  decoration: BoxDecoration(
                    color: kFieldBorder,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Recuerdo del ${date.day}/${date.month}/${date.year}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: kInk,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Escribe algo sobre este día...',
                  ),
                ),
                const SizedBox(height: 12),
                if (selectedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      selectedImage!,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  )
                else if (_selectedMemory?['imageUrl'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _selectedMemory!['imageUrl'],
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPurple,
                        foregroundColor: kInk,
                        shape: const StadiumBorder(),
                        minimumSize: const Size(140, 44),
                      ),
                      onPressed: () async {
                        final picked = await ImagePicker()
                            .pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setModalState(() {
                            selectedImage = File(picked.path);
                          });
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Subir imagen'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreenPastel,
                        foregroundColor: kInk,
                        shape: const StadiumBorder(),
                        minimumSize: const Size(140, 44),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (_isFutureDay(date)) {
                                _showDialog(
                                  'Fecha no permitida',
                                  'No puedes guardar recuerdos en fechas futuras.',
                                  success: false,
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);
                              try {
                                final userId = user.uid;
                                final dateId =
                                    "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

                                String? imageUrl =
                                    _selectedMemory?['imageUrl'];

                                if (selectedImage != null) {
                                  final ref = FirebaseStorage.instance
                                      .ref()
                                      .child('diary_images/$userId/$dateId.jpg');
                                  final uploadTask =
                                      await ref.putFile(selectedImage!);
                                  imageUrl =
                                      await uploadTask.ref.getDownloadURL();
                                }

                                await FirebaseFirestore.instance
                                    .collection('memories')
                                    .doc(userId)
                                    .collection('user_memories')
                                    .doc(dateId)
                                    .set({
                                  'date': date.toIso8601String(),
                                  'text': textCtrl.text.trim(),
                                  'imageUrl': imageUrl,
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });

                                if (mounted) Navigator.pop(ctx);

                                _showDialog(
                                  'Recuerdo guardado',
                                  'Tu recuerdo se ha guardado correctamente.',
                                  success: true,
                                );

                                await _loadMemory(date);
                              } catch (e) {
                                _showDialog(
                                  'Error al guardar',
                                  'Ocurrió un problema al guardar el recuerdo.\n\n$e',
                                  success: false,
                                );
                              } finally {
                                setModalState(() => isSaving = false);
                              }
                            },
                      icon: const Icon(Icons.save),
                      label: Text(isSaving ? 'Guardando...' : 'Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSelectDay(DateTime selected, DateTime focused) async {
    if (_isFutureDay(selected)) {
      _showDialog(
        'Fecha no permitida',
        'No puedes seleccionar fechas futuras para guardar recuerdos.',
        success: false,
      );
      return;
    }

    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
    });

    await _loadMemory(selected);

    final hasMemory = _selectedMemory != null &&
        ((_selectedMemory!['text'] ?? '').toString().isNotEmpty ||
            _selectedMemory!['imageUrl'] != null);

    final wantsToProceed = await _confirmDialog(
      hasMemory ? 'Modificar recuerdo' : 'Subir recuerdo',
      hasMemory
          ? 'Ya existe un recuerdo en esta fecha. ¿Quieres modificarlo?'
          : '¿Deseas subir un recuerdo para el ${selected.day}/${selected.month}/${selected.year}?',
    );

    if (!wantsToProceed) return;

    _openMemoryDialog(selected);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = _selectedDay ?? _onlyDate(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de recuerdos'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: kInk,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            // Contenedor con borde azul
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: kBlue, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TableCalendar(
                locale: 'es_ES',
                firstDay: DateTime(2020),
                lastDay: DateTime(2100),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month, // fija vista mensual
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false, // quita “2 weeks”
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: kInk,
                  ),
                ),
                calendarStyle: const CalendarStyle(
                  defaultTextStyle: TextStyle(color: kInk),
                  weekendTextStyle: TextStyle(color: kInk),
                  outsideTextStyle: TextStyle(color: kGrey1),
                  todayDecoration:
                      BoxDecoration(color: kBlue, shape: BoxShape.circle),
                  selectedDecoration:
                      BoxDecoration(color: kPurple, shape: BoxShape.circle),
                ),
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: (selected, focused) async {
                  await _onSelectDay(selected, focused);
                },
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedMemory != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildMemoryCard(selectedDate),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryCard(DateTime selectedDate) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kFieldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado con degradado y fecha
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kBlue.withOpacity(0.35), kPurple.withOpacity(0.35)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.bookmark, color: kInk),
                const SizedBox(width: 8),
                Text(
                  _formatDateEs(selectedDate),
                  style: const TextStyle(
                    color: kInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((_selectedMemory!['text'] ?? '').toString().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kFieldFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kFieldBorder),
                    ),
                    child: Text(
                      _selectedMemory!['text'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: kInk,
                        height: 1.35,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (_selectedMemory?['imageUrl'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 4 / 5,
                      child: Image.network(
                        _selectedMemory!['imageUrl'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (_selectedMemory?['imageUrl'] != null)
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: kBlue,
                            shape: const StadiumBorder(),
                            minimumSize: const Size.fromHeight(44),
                          ),
                          onPressed: () =>
                              _showImagePreview(_selectedMemory!['imageUrl']),
                          icon: const Icon(Icons.zoom_in, color: kInk),
                          label: const Text(
                            'Ver imagen',
                            style: TextStyle(
                              color: kInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (_selectedMemory?['imageUrl'] != null)
                      const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: kGreenPastel,
                          shape: const StadiumBorder(),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: () {
                          if (_selectedDay != null) {
                            _openMemoryDialog(_selectedDay!);
                          }
                        },
                        icon: const Icon(Icons.edit, color: kInk),
                        label: const Text(
                          'Editar',
                          style: TextStyle(
                            color: kInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
