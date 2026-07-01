import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/modelos.dart';

// ============================================================
// SERVICIO DE BACKUP — MedidorHN / AguaLuz HN
// Exporta las lecturas de una propiedad a JSON o CSV, las guarda
// en el almacenamiento privado de la app y permite compartirlas
// (WhatsApp, correo, Drive, guardar en el dispositivo, etc.)
// ============================================================

class BackupService {
  BackupService._();
  static final BackupService instancia = BackupService._();

  // Última exportación por propiedad (en memoria; se reinicia al
  // cerrar la app). Si más adelante se necesita que persista entre
  // sesiones, se puede guardar con shared_preferences.
  final Map<String, DateTime> _ultimaExportacion = {};

  // ── Exportar a JSON ──────────────────────────────────────
  String exportarJSON(Propiedad prop) {
    final data = {
      'id': prop.id,
      'nombre': prop.nombre,
      'direccion': prop.direccion,
      'colonia': prop.colonia,
      'servicios': prop.servicios.map((s) => s.name).toList(),
      'lecturas': prop.lecturas
          .map((l) => {
                'mes': l.mes,
                'tipo': l.tipo.name,
                'valor': l.valor,
                'fecha': l.fecha.toIso8601String(),
                'fotoPath': l.fotoPath,
              })
          .toList(),
      'exportadoEn': DateTime.now().toIso8601String(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // ── Exportar a CSV ───────────────────────────────────────
  String exportarCSV(Propiedad prop) {
    final filas = <List<dynamic>>[
      ['Propiedad', 'Dirección', 'Colonia', 'Mes', 'Servicio', 'Valor', 'Fecha'],
      ...prop.lecturas.map((l) => [
            prop.nombre,
            prop.direccion,
            prop.colonia,
            l.mes,
            l.tipo.nombre,
            l.valor,
            l.fecha.toIso8601String().split('T').first,
          ]),
    ];
    return const ListToCsvConverter().convert(filas);
  }

  // ── Vista previa (primeras líneas) ───────────────────────
  String vistaPrevia(String contenido, {int maxLineas = 8}) {
    final lineas = contenido.split('\n');
    if (lineas.length <= maxLineas) return contenido;
    return '${lineas.take(maxLineas).join('\n')}\n… (${lineas.length - maxLineas} líneas más)';
  }

  // ── Nombre de archivo seguro a partir del nombre de la propiedad ──
  String _normalizar(String texto) => texto
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  // ── Guardar contenido como archivo en almacenamiento de la app ──
  Future<File> guardarArchivo(String contenido, String nombre) async {
    final dir = await getApplicationDocumentsDirectory();
    final archivo = File('${dir.path}/$nombre');
    return archivo.writeAsString(contenido);
  }

  // ── Flujo completo: generar contenido + guardar + marcar fecha ──
  Future<File> exportarYGuardar(Propiedad prop, {required bool comoJSON}) async {
    final contenido = comoJSON ? exportarJSON(prop) : exportarCSV(prop);
    final extension = comoJSON ? 'json' : 'csv';
    final nombreArchivo =
        '${_normalizar(prop.nombre)}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final archivo = await guardarArchivo(contenido, nombreArchivo);
    _ultimaExportacion[prop.id] = DateTime.now();
    return archivo;
  }

  // ── Compartir archivo ya generado ────────────────────────
  Future<void> compartirArchivo(File file, {String? textoExtra}) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: textoExtra ?? 'Backup de lecturas — AguaLuz HN',
    );
  }

  DateTime? obtenerUltimaExportacion(String propiedadId) =>
      _ultimaExportacion[propiedadId];
}