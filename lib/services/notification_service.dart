import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

// ============================================================
// SERVICIO DE NOTIFICACIONES — MedidorHN / AguaLuz HN
// v2.0 — Notificaciones inmediatas + programadas día 25
// ============================================================

class NotificationService {
  NotificationService._();
  static final NotificationService instancia = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _inicializado = false;

  // ── Inicializar ──────────────────────────────────────────
  Future<void> inicializar() async {
    if (_inicializado) return;

    // Inicializar zonas horarias
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Tegucigalpa'));

    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onTap,
    );

    // Pedir permisos Android 13+
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    _inicializado = true;
  }

  void _onTap(NotificationResponse response) {}

  // ── Canal Android ────────────────────────────────────────
  static const _canalId = 'medidor_hn_recordatorio';

  static final _canal = AndroidNotificationDetails(
    _canalId,
    'Recordatorios de lectura',
    channelDescription: 'Recordatorio mensual para registrar lecturas',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/launcher_icon',
    color: Color(0xFF00BCD4),
    enableLights: true,
    enableVibration: true,
    styleInformation: BigTextStyleInformation(''),
  );

  static final _detalles = NotificationDetails(android: _canal);

  // ── Notificación inmediata ───────────────────────────────
  Future<void> mostrarNotificacionPrueba() async {
    await inicializar();
    await _plugin.show(
      0,
      '💧⚡ ¡Hora de registrar tus lecturas!',
      'Ya es fin de mes. Abrí AguaLuz HN y anotá el agua, luz y gas '
          'para mantener tu historial al día.',
      _detalles,
    );
  }

  // ── Recordatorio de servicio ─────────────────────────────
  Future<void> recordatorioServicio({
    required String nombrePropiedad,
    required String servicio,
    required String emoji,
  }) async {
    await inicializar();
    await _plugin.show(
      servicio.hashCode,
      '$emoji Lectura de $servicio pendiente',
      'Registrá la lectura de $servicio en "$nombrePropiedad" '
          'para no perder tu historial mensual.',
      _detalles,
    );
  }

  // ── Alerta de consumo alto ───────────────────────────────
  Future<void> alertaConsumoAlto({
    required String nombrePropiedad,
    required String servicio,
    required String emoji,
    required double porcentaje,
  }) async {
    await inicializar();
    await _plugin.show(
      ('alerta_$servicio').hashCode,
      '$emoji Consumo alto en $servicio',
      '"$nombrePropiedad" tiene un consumo ${porcentaje.toStringAsFixed(0)}% '
          'por encima del promedio este mes.',
      _detalles,
    );
  }

  // ── Programar recordatorio mensual (día 25 a las 8am) ───
  // Cancela el anterior y programa el próximo día 25
  Future<void> programarRecordatorioMensual() async {
    await inicializar();

    // Cancelar recordatorio anterior si existe
    await _plugin.cancel(999);

    final ahora = tz.TZDateTime.now(tz.local);
    // Calcular próximo día 25
    var proximo = tz.TZDateTime(
      tz.local, ahora.year, ahora.month, 25, 8, 0,
    );
    // Si ya pasó el 25 de este mes, ir al mes siguiente
    if (ahora.isAfter(proximo)) {
      proximo = tz.TZDateTime(
        tz.local,
        ahora.month == 12 ? ahora.year + 1 : ahora.year,
        ahora.month == 12 ? 1 : ahora.month + 1,
        25, 8, 0,
      );
    }

    await _plugin.zonedSchedule(
      999,
      '📊 ¡Registrá tus lecturas de este mes!',
      'Ya casi termina el mes. Abrí AguaLuz HN y anotá el agua, '
          'la luz y el gas para mantener tu historial al día.',
      proximo,
      _detalles,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Cancelar todas ───────────────────────────────────────
  Future<void> cancelarTodas() async {
    await _plugin.cancelAll();
  }
}