import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Timezone: datos + API
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// =============================================================
/// SERVICIO CENTRALIZADO DE NOTIFICACIONES
/// =============================================================
/// - Inicialización y permisos.
/// - Programación de recordatorios recurrentes por cadencia.
/// - Cancelación y consulta de notificaciones pendientes.
/// =============================================================

enum MemoryCadence {
  weekly,
  biweekly,
  monthly,
  quarterly,
  semiannual,
  annual,
}

/// Convierte un texto a su tipo de cadencia correspondiente.
MemoryCadence cadenceFromString(String v) {
  switch (v) {
    case 'weekly':
      return MemoryCadence.weekly;
    case 'biweekly':
      return MemoryCadence.biweekly;
    case 'monthly':
      return MemoryCadence.monthly;
    case 'quarterly':
      return MemoryCadence.quarterly;
    case 'semiannual':
      return MemoryCadence.semiannual;
    case 'annual':
      return MemoryCadence.annual;
    default:
      return MemoryCadence.monthly;
  }
}

class NotificationsService {
  // Instancia interna del plugin
  static final _plugin = FlutterLocalNotificationsPlugin();

  // Getter público (por si necesitas acceso directo en alguna vista)
  static FlutterLocalNotificationsPlugin get plugin => _plugin;

  // Canal de notificaciones en Android
  static const _androidChannelId = 'memories_reminders';
  static const _androidChannelName = 'Recordatorios de recuerdos';
  static const _androidChannelDesc = 'Notificaciones periódicas de recuerdos';

  /// Inicializa el sistema de notificaciones locales.
  /// Debe ejecutarse en main() antes de runApp().
  static Future<void> init() async {
    // ✅ Inicializa zonas horarias para usar tz.TZDateTime correctamente
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);

    // Android 13+: permiso en runtime
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // ✔️ Método disponible en tu versión del paquete:
    await androidPlugin?.requestNotificationsPermission();

    // iOS: permisos
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Crear canal en Android (si no existe)
    const androidChannel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDesc,
      importance: Importance.high,
    );
    await androidPlugin?.createNotificationChannel(androidChannel);
  }

  /// Cancela todas las notificaciones vinculadas a un recuerdo.
  static Future<void> cancelAllForMemory(String memoryId) async {
    final base = _baseId(memoryId);
    for (var i = 0; i < 30; i++) {
      await _plugin.cancel(base + i);
    }
  }

  /// Programa recordatorios recurrentes para un recuerdo según su cadencia.
  ///
  /// Usa `AndroidScheduleMode.inexactAllowWhileIdle` para evitar
  /// el permiso de alarmas exactas en Android 12+.
  static Future<void> scheduleForMemory({
    required String memoryId,
    required String title,
    required DateTime anchorDate,
    required MemoryCadence cadence,
    int occurrences = 12,
  }) async {
    // Limpia notificaciones anteriores del mismo recuerdo
    await cancelAllForMemory(memoryId);

    final baseId = _baseId(memoryId);
    final now = tz.TZDateTime.now(tz.local);

    // Fechas futuras a partir de anchorDate
    final dates = _generateOccurrences(anchorDate, cadence, occurrences)
        .map((d) => tz.TZDateTime.from(d, tz.local))
        .where((d) => d.isAfter(now))
        .toList();

    // Reusar detalles entre iteraciones
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    for (var i = 0; i < dates.length; i++) {
      final id = baseId + i;

      await _plugin.zonedSchedule(
        id,
        'Recordatorio de recuerdo',
        title,
        dates[i],
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // ✅ clave
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
        payload: memoryId, // String
      );
    }

    if (kDebugMode) {
      debugPrint('Programadas ${dates.length} notificaciones para $memoryId');
    }
  }

  /// Lista de notificaciones pendientes (para badge o vista de notificaciones).
  static Future<List<PendingNotificationRequest>> pendingNotificationRequests() {
    return _plugin.pendingNotificationRequests();
  }

  /// Cancela una sola notificación por ID.
  static Future<void> cancel(int id) async => _plugin.cancel(id);

  /// Cancela todas las notificaciones programadas.
  static Future<void> cancelAll() async => _plugin.cancelAll();

  /// Identificador numérico estable a partir del memoryId.
  static int _baseId(String memoryId) {
    return (memoryId.hashCode & 0x7fffffff) % 1000000;
  }

  /// Genera fechas futuras según la cadencia.
  static Iterable<DateTime> _generateOccurrences(
      DateTime anchor, MemoryCadence c, int n) sync* {
    DateTime d = DateTime(
      anchor.year,
      anchor.month,
      anchor.day,
      anchor.hour,
      anchor.minute,
    );
    for (int i = 0; i < n; i++) {
      if (i > 0) {
        switch (c) {
          case MemoryCadence.weekly:
            d = d.add(const Duration(days: 7));
            break;
          case MemoryCadence.biweekly:
            d = d.add(const Duration(days: 14));
            break;
          case MemoryCadence.monthly:
            d = _addMonths(d, 1);
            break;
          case MemoryCadence.quarterly:
            d = _addMonths(d, 3);
            break;
          case MemoryCadence.semiannual:
            d = _addMonths(d, 6);
            break;
          case MemoryCadence.annual:
            d = _addMonths(d, 12);
            break;
        }
      }
      yield d;
    }
  }

  /// Suma meses a una fecha manejando correctamente el fin de mes.
  static DateTime _addMonths(DateTime d, int m) {
    final newMonth = d.month + m;
    final year = d.year + ((newMonth - 1) ~/ 12);
    final month = ((newMonth - 1) % 12) + 1;
    final day = min(d.day, _daysInMonth(year, month));
    return DateTime(year, month, day, d.hour, d.minute);
  }

  /// Número de días del mes.
  static int _daysInMonth(int year, int month) {
    final first = DateTime(year, month, 1);
    final next =
        (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return next.difference(first).inDays;
  }
}
