import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/notifications_service.dart';
import '../theme.dart';

/// ===================== Helpers locales (DIÁLOGOS) =====================

Future<void> _showOkDialog(
  BuildContext context, {
  required String title,
  required String message,
  String okText = 'Aceptar',
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: Text(message),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: kPurple,
            foregroundColor: kInk,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(okText),
        ),
      ],
    ),
  );
}

Future<bool> _showConfirmDialog(
  BuildContext context, {
  String title = 'Confirmar',
  required String message,
  String cancelText = 'Cancelar',
  String okText = 'Aceptar',
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: kPurple,
            foregroundColor: kInk,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(okText),
        ),
      ],
    ),
  );
  return res ?? false;
}
/// =====================================================================

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  static const route = '/notifications';

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<PendingNotificationRequest> _pending = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() => _loading = true);
    final list = await NotificationsService.pendingNotificationRequests();
    if (!mounted) return;
    list.sort((a, b) => a.id.compareTo(b.id));
    setState(() {
      _pending = list;
      _loading = false;
    });
  }

  Future<void> _cancel(int id) async {
    final ok = await _showConfirmDialog(context, message: '¿Eliminar este recordatorio?');
    if (!ok) return;
    await NotificationsService.cancel(id);
    await _loadPending();
    if (!mounted) return;
    await _showOkDialog(context, title: 'Eliminado', message: 'Se eliminó el recordatorio.');
  }

  Future<void> _cancelAll() async {
    if (_pending.isEmpty) return;
    final ok = await _showConfirmDialog(context, message: '¿Eliminar TODOS los recordatorios?');
    if (!ok) return;
    await NotificationsService.cancelAll();
    await _loadPending();
    if (!mounted) return;
    await _showOkDialog(context, title: 'Listo', message: 'Se eliminaron todas las notificaciones.');
  }

  ButtonStyle _compact(ButtonStyle? base) {
    final compact = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      minimumSize: const Size(0, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
    return (base ?? const ButtonStyle()).merge(compact);
  }

  @override
  Widget build(BuildContext context) {
    final title =
        _pending.isEmpty ? 'Notificaciones' : 'Notificaciones (${_pending.length})';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Actualizar', onPressed: _loadPending),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Eliminar todas',
            onPressed: _pending.isEmpty ? null : _cancelAll,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPending,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _pending.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pending.length,
                    itemBuilder: (context, i) {
                      final n = _pending[i];
                      final title = (n.title?.trim().isNotEmpty ?? false)
                          ? n.title!
                          : 'Recordatorio de recuerdo';
                      final body = (n.body?.trim().isNotEmpty ?? false) ? n.body! : null;

                      return Card(
                        elevation: 0,
                        color: kFieldFill,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: kFieldBorder),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.notifications_active_rounded, color: kBlue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: kInk,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (body != null) const SizedBox(height: 6),
                              if (body != null)
                                Text(body, style: const TextStyle(color: kGrey1, fontSize: 15)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    style: _compact(TextButton.styleFrom(
                                      backgroundColor: kPurple,
                                      foregroundColor: kInk,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                    )),
                                    onPressed: () => _showTrainMemoryDialog(context, n),
                                    child: const Text('Ver recuerdo'),
                                  ),
                                  const SizedBox(width: 12),
                                  FilledButton(
                                    style: _compact(FilledButton.styleFrom(
                                      backgroundColor: Color(0xFFFF9CA0),
                                      foregroundColor: kInk,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                    )),
                                    onPressed: () => _cancel(n.id),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

/// ╭──────────────────────────────────────────────────────────────╮
/// │ D I Á L O G O   D E   R E C U E R D O   C O N   T R É N     │
/// ╰──────────────────────────────────────────────────────────────╯
Future<void> _showTrainMemoryDialog(
    BuildContext context, PendingNotificationRequest n) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final payload = n.payload ?? '';
  final parts = payload.split('/');
  final memoryId = parts.isNotEmpty ? parts.last : null;

  if (userId == null || memoryId == null) {
    await _showOkDialog(context, title: 'Error', message: 'No se pudo identificar el recuerdo.');
    return;
  }

  final doc = await FirebaseFirestore.instance
      .collection('memories')
      .doc(userId)
      .collection('user_memories')
      .doc(memoryId)
      .get();

  if (!doc.exists) {
    await _showOkDialog(context, title: 'No encontrado', message: 'Este recuerdo ya no existe.');
    return;
  }

  final data = doc.data()!;
  final text = data['text'] ?? 'Sin descripción';
  final date = (data['date'] as String?) ?? '';
  final imageUrl = data['imageUrl'] as String?;

  await showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    pageBuilder: (_, __, ___) => const SizedBox(),
    transitionDuration: const Duration(milliseconds: 600),
    transitionBuilder: (_, anim, __, ___) {
      return FadeTransition(
        opacity: anim,
        child: TrainMemoryDialog(imageUrl: imageUrl, text: text, date: date),
      );
    },
  );
}

/// ─────────────── D I Á L O G O   A N I M A D O ───────────────
class TrainMemoryDialog extends StatefulWidget {
  final String? imageUrl;
  final String text;
  final String date;

  const TrainMemoryDialog({
    super.key,
    required this.imageUrl,
    required this.text,
    required this.date,
  });

  @override
  State<TrainMemoryDialog> createState() => _TrainMemoryDialogState();
}

class _TrainMemoryDialogState extends State<TrainMemoryDialog>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _smoke; // impulsa humo y ruedas
  late final AnimationController _leave;
  late final Animation<Offset> _trainIn;
  late final Animation<Offset> _trainOut;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();

    // Cartoon rápido
    _smoke = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat();

    _leave = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    // ⟶ ENTRA de DERECHA → IZQUIERDA
    _trainIn = Tween<Offset>(begin: const Offset(1.2, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic));

    // ⟵ SALE hacia la IZQUIERDA
    _trainOut = Tween<Offset>(begin: Offset.zero, end: const Offset(-1.3, 0))
        .animate(CurvedAnimation(parent: _leave, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _intro.dispose();
    _smoke.dispose();
    _leave.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    if (_closing) return;
    setState(() => _closing = true);
    // dejamos humo + ruedas girando durante la salida
    await _leave.forward();
    _smoke.stop();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final dialogW = w * 0.92;

    return Center(
      child: Material(
        color: Colors.black.withOpacity(0.35),
        child: Center(
          child: Container(
            width: dialogW.clamp(320, 560),
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'El recuerdo ha llegado',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kInk, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),

                    _MemoryCardWhiteBorder(
                      imageUrl: widget.imageUrl,
                      text: widget.text,
                      date: widget.date,
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      height: 160,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Vía PINTADA ABAJO
                          Positioned.fill(child: CustomPaint(painter: _TrackPainter())),

                          // Humo blanco (ajustado a chimenea)
                          Positioned(left: 148, bottom: 112, child: _SmokeLoop(controller: _smoke, size: 22, phase: 0.00)),
                          Positioned(left: 164, bottom: 118, child: _SmokeLoop(controller: _smoke, size: 26, phase: 0.33)),
                          Positioned(left: 182, bottom: 124, child: _SmokeLoop(controller: _smoke, size: 20, phase: 0.66)),

                          // Tren encima de la vía: entra (→ ←) y sale (←)
                          SlideTransition(
                            position: _trainOut,
                            child: SlideTransition(
                              position: _trainIn,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: _TrainGraphicV3(spin: _smoke),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: kPurple,
                          foregroundColor: kInk,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _handleClose,
                        child: const Text('Cerrar'),
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

/// ─────────────────── Tarjeta blanca con borde azul ───────────────────
class _MemoryCardWhiteBorder extends StatelessWidget {
  final String? imageUrl;
  final String text;
  final String date;

  const _MemoryCardWhiteBorder({
    required this.imageUrl,
    required this.text,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 6,
      shadowColor: kBlue.withOpacity(0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kBlue, width: 1.4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.white,
                  height: 200,
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Image.network(imageUrl!),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kInk,
                fontSize: 16,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kBlue.withOpacity(0.10),
                border: Border.all(color: kBlue.withOpacity(0.25)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Fecha: ${date.split("T").first}',
                style: const TextStyle(color: kInk, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────── Tren grande tipo maqueta infantil (3 coches) ───────────────
class _TrainGraphicV3 extends StatelessWidget {
  final Animation<double> spin; // ruedas cartoon rápidas
  const _TrainGraphicV3({required this.spin});

  Widget _wheel({required double left, required double bottom}) {
    return AnimatedBuilder(
      animation: spin,
      builder: (_, __) {
        final angle = spin.value * math.pi * 4; // rápido
        return Positioned(
          left: left,
          bottom: bottom,
          child: Transform.rotate(
            angle: angle,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(width: 28, height: 28, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
                Container(width: 16, height: 16, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _connector({required double left, required double bottom}) {
    return Positioned(
      left: left,
      bottom: bottom,
      child: Container(
        width: 16,
        height: 4,
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  Widget _carBody({
    required double left,
    required double bottom,
    required double width,
    required double height,
    required Color color,
    bool hasRoof = false,
    bool hasWindow = true,
  }) {
    return Positioned(
      left: left,
      bottom: bottom,
      child: Stack(
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          ),
          if (hasRoof)
            Positioned(
              top: -8,
              left: width * 0.08,
              child: Container(
                width: width * 0.84,
                height: 10,
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
              ),
            ),
          if (hasWindow)
            Positioned(
              top: height * 0.22,
              left: width * 0.12,
              child: Container(
                width: width * 0.28,
                height: height * 0.44,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(6)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chimney({required double left, required double bottom}) {
    return Positioned(
      left: left,
      bottom: bottom,
      child: Container(width: 22, height: 36, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6))),
    );
  }

  Widget _frontLight({required double left, required double bottom}) {
    return Positioned(
      left: left,
      bottom: bottom,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7B2),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: const Color(0xFFFFF7B2).withOpacity(0.6), blurRadius: 10, spreadRadius: 3)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double baseBottom = 26;
    const double carW = 118;
    const double carH = 54;

    const Color locoColor = kPurple;
    const Color wagonPink = Color(0xFFFF9CA0);
    const Color wagonBlue = kBlue;

    return SizedBox(
      width: 420,
      height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Locomotora
          _carBody(left: 60, bottom: baseBottom, width: carW, height: carH, color: locoColor, hasRoof: true, hasWindow: true),
          Positioned(
            left: 44,
            bottom: baseBottom,
            child: Container(width: 32, height: carH, decoration: BoxDecoration(color: locoColor, borderRadius: BorderRadius.circular(16))),
          ),
          _chimney(left: 150, bottom: baseBottom + carH - 6),
          _frontLight(left: 46, bottom: baseBottom + carH * 0.55),
          _wheel(left: 82, bottom: baseBottom - 26),
          _wheel(left: 122, bottom: baseBottom - 26),
          _wheel(left: 162, bottom: baseBottom - 26),

          // Conector 1
          _connector(left: 178, bottom: baseBottom + 8),

          // Vagón rosado
          _carBody(left: 194, bottom: baseBottom, width: carW, height: carH, color: wagonPink, hasRoof: false, hasWindow: false),
          _wheel(left: 214, bottom: baseBottom - 26),
          _wheel(left: 274, bottom: baseBottom - 26),

          // Conector 2
          _connector(left: 312, bottom: baseBottom + 8),

          // Vagón azul
          _carBody(left: 328, bottom: baseBottom, width: carW, height: carH, color: wagonBlue, hasRoof: false, hasWindow: false),
          _wheel(left: 348, bottom: baseBottom - 26),
          _wheel(left: 408, bottom: baseBottom - 26),
        ],
      ),
    );
  }
}

/// ─────────────── Vía (debajo del tren) ───────────────
class _TrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rail = Paint()
      ..color = const Color(0xFFB9B9C9)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final sleeper = Paint()
      ..color = const Color(0xFF9E9EB2)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final yUpper = size.height - 26; // riel superior
    final yLower = size.height - 18; // riel inferior

    canvas.drawLine(Offset(12, yUpper), Offset(size.width - 12, yUpper), rail);
    canvas.drawLine(Offset(12, yLower), Offset(size.width - 12, yLower), rail);

    for (double x = 20; x < size.width - 10; x += 18) {
      canvas.drawLine(Offset(x, yUpper - 4), Offset(x, yLower + 4), sleeper);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ─────────────── Humo blanco en loop ───────────────
class _SmokeLoop extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final double phase;

  const _SmokeLoop({
    required this.controller,
    required this.size,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        double t = (controller.value + phase) % 1.0;
        final dy = -32 * t;
        final scale = 0.7 + 0.7 * t;
        final opacity = (t < 0.15) ? (t / 0.15) : (1.0 - t);

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              scale: scale,
              child: _SmokePuff(size: size),
            ),
          ),
        );
      },
    );
  }
}

class _SmokePuff extends StatelessWidget {
  final double size;
  const _SmokePuff({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 8, spreadRadius: 2),
        ],
      ),
    );
  }
}

/// Estado vacío
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'No hay notificaciones pendientes.\n\nPrograma un recuerdo desde el calendario o pulsa “Actualizar”.',
          textAlign: TextAlign.center,
          style: TextStyle(color: kGrey1, fontSize: 16, height: 1.35),
        ),
      ),
    );
  }
}
