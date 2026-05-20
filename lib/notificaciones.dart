import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // ─────────────────────────────────────────
  // INICIALIZAR
  // ─────────────────────────────────────────
  static Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings);
  }

  // ─────────────────────────────────────────
  // NOTIFICACIÓN DIARIA — 8:00 AM
  // Para cambiar hora modifica: hora y minuto
  // ─────────────────────────────────────────
  static Future<void> programarRecordatorioDiario() async {
    final mexico = tz.getLocation('America/Mexico_City');
    final ahora = tz.TZDateTime.now(mexico);

    var horaNotificacion = tz.TZDateTime(
      mexico,
      ahora.year,
      ahora.month,
      ahora.day,
      8,  // ← hora (8 = 8 AM)
      0,  // ← minuto
    );

    if (horaNotificacion.isBefore(ahora)) {
      horaNotificacion = horaNotificacion.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'dmstride_diario',
      'Recordatorio Diario',
      channelDescription: 'Recordatorio diario para glucosa y presión arterial',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _notifications.zonedSchedule(
      2,
      'DMstride',
      'No olvides registrar tu glucosa y presión arterial de hoy para mantener actualizado tu monitoreo.',
      horaNotificacion,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ─────────────────────────────────────────
  // NOTIFICACIÓN SEMANAL — Domingo 8:00 PM
  // Para cambiar día: DateTime.sunday → monday, etc.
  // Para cambiar hora: modifica 20 y 0
  // ─────────────────────────────────────────
  static Future<void> programarRecordatorioSemanal() async {
    final mexico = tz.getLocation('America/Mexico_City');
    final ahora = tz.TZDateTime.now(mexico);

    var horaNotificacion = tz.TZDateTime(
      mexico,
      ahora.year,
      ahora.month,
      ahora.day,
      20, // ← hora (20 = 8 PM)
      0,  // ← minuto
    );

    while (horaNotificacion.weekday != DateTime.sunday) {
      horaNotificacion = horaNotificacion.add(const Duration(days: 1));
    }

    if (horaNotificacion.isBefore(ahora)) {
      horaNotificacion = horaNotificacion.add(const Duration(days: 7));
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'dmstride_semanal',
      'Recordatorio Semanal',
      channelDescription: 'Recordatorio semanal para fotografía del pie',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _notifications.zonedSchedule(
      1,
      'DMstride',
      'Es momento de realizar tu revisión semanal del pie y subir nuevas fotografías para continuar con tu monitoreo.',
      horaNotificacion,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ─────────────────────────────────────────
  // PRUEBA — Llegan de inmediato
  // ─────────────────────────────────────────
  static Future<void> probarNotificacionSemanal() async {
    await _notifications.show(
      10,
      'DMstride',
      'Es momento de realizar tu revisión semanal del pie y subir nuevas fotografías para continuar con tu monitoreo.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dmstride_prueba',
          'Prueba',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> probarNotificacionDiaria() async {
    await _notifications.show(
      11,
      'DMstride',
      'No olvides registrar tu glucosa y presión arterial de hoy para mantener actualizado tu monitoreo.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dmstride_prueba',
          'Prueba',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // CANCELAR TODAS
  // ─────────────────────────────────────────
  static Future<void> cancelarTodo() async {
    await _notifications.cancelAll();
  }
}