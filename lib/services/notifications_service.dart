import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// =============================================================
/// SERVICIO CENTRALIZADO DE NOTIFICACIONES
/// =============================================================
/// - Inicializa permisos y canal de Android/iOS.
/// - Programa recordatorios periódicos por cadencia.
/// - Corrige el problema de "exact alarms not permitted".
/// - Usa zona horaria local y evita fechas pasadas.
/// =============================================================

enum MemoryCadence {
  hourly1,
  hourly2,
  hourly6,
  daily1,
  daily2,
  weekly,
  biweekly,
  monthly,
  quarterly,
  semiannual,
  annual,
}

/// Convierte texto de base de datos a enum
MemoryCadence cadenceFromString(String v) {
  switch (v) {
    case 'hourly1':
      return MemoryCadence.hourly1;
    case 'hourly2':
      return MemoryCadence.hourly2;
    case 'hourly6':
      return MemoryCadence.hourly6;
    case 'daily1':
      return MemoryCadence.daily1;
    case 'daily2':
      return MemoryCadence.daily2;
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
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static FlutterLocalNotificationsPlugin get plugin => _plugin;

  static const _androidChannelId = 'memories_reminders';
  static const _androidChannelName = 'Recordatorios de recuerdos';
  static const _androidChannelDesc =
      'Notificaciones periódicas de recuerdos programados por el usuario.';

  /// =============================================================
  /// ✅ Inicialización segura (una sola vez)
  /// =============================================================
  static Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings =
          InitializationSettings(android: androidInit, iOS: iosInit);

      await _plugin.initialize(initSettings);

      // Android: permisos y canal
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();

      const androidChannel = AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDesc,
        importance: Importance.high,
      );
      await androidPlugin?.createNotificationChannel(androidChannel);

      // iOS: permisos
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      _initialized = true;
      if (kDebugMode) debugPrint('✅ Notificaciones inicializadas');
    } catch (e) {
      debugPrint('⚠️ Error al inicializar notificaciones: $e');
    }
  }

  static Future<void> ensureInitialized() async {
    if (!_initialized) await init();
  }

  /// =============================================================
  /// 🕒 Programar notificaciones con cadencia personalizada
  /// =============================================================
  static Future<void> scheduleForMemory({
    required String memoryId,
    required String title,
    required DateTime anchorDate,
    required MemoryCadence cadence,
    int occurrences = 12,
  }) async {
    await ensureInitialized();

    // 🔄 Cancelar anteriores del mismo recuerdo
    await cancelAllForMemory(memoryId);

    // ✅ Asegurar que el ancla esté en el futuro
    final now = DateTime.now();
    if (anchorDate.isBefore(now)) {
      anchorDate = now.add(const Duration(minutes: 1));
    }

    // ✅ Convertir a zona horaria local
    anchorDate = tz.TZDateTime.from(anchorDate, tz.local);

    final baseId = _baseId(memoryId);
    final nowTz = tz.TZDateTime.now(tz.local);

    // 🔁 Generar lista de ocurrencias (en futuro)
    final occurrencesList = _generateOccurrencesFromAnchorPlusInterval(
      anchorDate,
      cadence,
      occurrences,
    )
        .map((d) => tz.TZDateTime.from(d, tz.local))
        .where((d) => d.isAfter(nowTz))
        .toList();

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

    for (var i = 0; i < occurrencesList.length; i++) {
      try {
        await _plugin.zonedSchedule(
          baseId + i,
          'Recordatorio de recuerdo',
          title,
          occurrencesList[i],
          details,
          // 🟣 CORREGIDO: ya no usa alarmas exactas
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidAllowWhileIdle: true,
          payload: memoryId,
        );
      } catch (e) {
        debugPrint('⚠️ Error al programar notificación $i: $e');
      }
    }

    if (kDebugMode) {
      debugPrint(
          '🕒 Programadas ${occurrencesList.length} notificaciones para $memoryId');
      for (var dt in occurrencesList) {
        debugPrint(' • ${dt.toLocal()}');
      }
    }
  }

  /// =============================================================
  /// ❌ Cancelar todas las notificaciones de un recuerdo
  /// =============================================================
  static Future<void> cancelAllForMemory(String memoryId) async {
    await ensureInitialized();
    final base = _baseId(memoryId);
    for (var i = 0; i < 50; i++) {
      try {
        await _plugin.cancel(base + i);
      } catch (e) {
        debugPrint('⚠️ Error al cancelar notificación $i: $e');
      }
    }
  }

  /// =============================================================
  /// 📋 Consultar pendientes
  /// =============================================================
  static Future<List<PendingNotificationRequest>>
      pendingNotificationRequests() async {
    await ensureInitialized();
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('⚠️ Error al obtener pendientes: $e');
      return [];
    }
  }

  static Future<void> cancel(int id) async {
    await ensureInitialized();
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('⚠️ Error al cancelar notificación $id: $e');
    }
  }

  static Future<void> cancelAll() async {
    await ensureInitialized();
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('⚠️ Error al cancelar todas: $e');
    }
  }

  // =============================================================
  // 🔧 Internos
  // =============================================================
  static int _baseId(String memoryId) {
    // ID estable y único (dentro del rango 100000–999999)
    return (memoryId.hashCode & 0x7fffffff) % 900000 + 100000;
  }

  static Iterable<DateTime> _generateOccurrencesFromAnchorPlusInterval(
      DateTime anchor, MemoryCadence c, int n) sync* {
    DateTime current =
        DateTime(anchor.year, anchor.month, anchor.day, anchor.hour, anchor.minute);
    for (int i = 0; i < n; i++) {
      current = _addCadence(current, c);
      yield current;
    }
  }

  static DateTime _addCadence(DateTime d, MemoryCadence c) {
    switch (c) {
      case MemoryCadence.hourly1:
        return d.add(const Duration(hours: 1));
      case MemoryCadence.hourly2:
        return d.add(const Duration(hours: 2));
      case MemoryCadence.hourly6:
        return d.add(const Duration(hours: 6));
      case MemoryCadence.daily1:
        return d.add(const Duration(days: 1));
      case MemoryCadence.daily2:
        return d.add(const Duration(days: 2));
      case MemoryCadence.weekly:
        return d.add(const Duration(days: 7));
      case MemoryCadence.biweekly:
        return d.add(const Duration(days: 14));
      case MemoryCadence.monthly:
        return _addMonths(d, 1);
      case MemoryCadence.quarterly:
        return _addMonths(d, 3);
      case MemoryCadence.semiannual:
        return _addMonths(d, 6);
      case MemoryCadence.annual:
        return _addMonths(d, 12);
    }
  }

  static DateTime _addMonths(DateTime d, int m) {
    final newMonth = d.month + m;
    final year = d.year + ((newMonth - 1) ~/ 12);
    final month = ((newMonth - 1) % 12) + 1;
    final day = min(d.day, _daysInMonth(year, month));
    return DateTime(year, month, day, d.hour, d.minute);
  }

  static int _daysInMonth(int year, int month) {
    final first = DateTime(year, month, 1);
    final next = (month == 12)
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return next.difference(first).inDays;
  }
}
