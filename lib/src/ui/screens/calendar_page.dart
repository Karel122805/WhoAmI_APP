import 'dart:io';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<String, dynamic>? _selectedMemory; // ← para mostrar recuerdos guardados

  /// 🔹 Cargar recuerdo existente (si lo hay)
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

  /// 🔹 Abrir modal para agregar/editar recuerdo
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Recuerdo del ${date.day}/${date.month}/${date.year}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Escribe algo sobre este día...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (selectedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(selectedImage!,
                        height: 150, fit: BoxFit.cover),
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
                    OutlinedButton.icon(
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
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() => isSaving = true);
                              try {
                                final userId = user.uid;
                                final dateId =
                                    "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

                                String? imageUrl = _selectedMemory?['imageUrl'];

                                // Subir imagen si se seleccionó una nueva
                                if (selectedImage != null) {
                                  final ref = FirebaseStorage.instance
                                      .ref()
                                      .child(
                                          'diary_images/$userId/$dateId.jpg');
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

                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Recuerdo guardado 💾'),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                await _loadMemory(date);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al guardar: $e'),
                                    backgroundColor: Colors.red,
                                  ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff2f4f7),
      appBar: AppBar(
        title: const Text('Calendario de recuerdos'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selected, focused) async {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
              await _loadMemory(selected);
              _openMemoryDialog(selected);
            },
          ),
          const SizedBox(height: 12),
          if (_selectedMemory != null)
            Expanded(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedMemory!['text'] ?? '',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        if (_selectedMemory?['imageUrl'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _selectedMemory!['imageUrl'],
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
