import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/datos.dart';
import '../models/modelos.dart';
import '../services/backup_service.dart';

// ============================================================
// PANTALLA BACKUP — AguaLuz HN
// Exportar lecturas de cada propiedad a JSON o CSV y compartirlas
// ============================================================

class PantallaBackup extends StatefulWidget {
  const PantallaBackup({super.key});
  @override
  State<PantallaBackup> createState() => _PantallaBackupState();
}

class _PantallaBackupState extends State<PantallaBackup> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        backgroundColor: AppTheme.fondo,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.verde.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.save_alt_rounded, color: AppTheme.verde, size: 15),
          ),
          const SizedBox(width: 10),
          const Text('Backup de Lecturas'),
        ]),
      ),
      body: propiedades.isEmpty
          ? Center(
              child: Text(
                'No hay propiedades para exportar',
                style: TextStyle(color: AppTheme.gris),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.aguaBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.agua.withValues(alpha: 0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded, color: AppTheme.agua, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Exportá las lecturas de cada propiedad y compartilas por WhatsApp, correo o guardalas en tu teléfono.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textoSecundario),
                      ),
                    ),
                  ]),
                ),
                ...propiedades.map((p) => _TarjetaBackup(propiedad: p)),
                const SizedBox(height: 12),
              ],
            ),
    );
  }
}

class _TarjetaBackup extends StatefulWidget {
  final Propiedad propiedad;
  const _TarjetaBackup({required this.propiedad});
  @override
  State<_TarjetaBackup> createState() => _TarjetaBackupState();
}

class _TarjetaBackupState extends State<_TarjetaBackup> {
  bool _cargando = false;
  String? _ultimoContenido;
  String? _ultimoFormato;
  File? _ultimoArchivo;

  Future<void> _exportar(bool comoJSON) async {
    setState(() => _cargando = true);
    try {
      final archivo = await BackupService.instancia
          .exportarYGuardar(widget.propiedad, comoJSON: comoJSON);
      final contenido = comoJSON
          ? BackupService.instancia.exportarJSON(widget.propiedad)
          : BackupService.instancia.exportarCSV(widget.propiedad);
      setState(() {
        _ultimoArchivo = archivo;
        _ultimoContenido = contenido;
        _ultimoFormato = comoJSON ? 'JSON' : 'CSV';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ ${widget.propiedad.nombre} exportada a $_ultimoFormato'),
        backgroundColor: AppTheme.verdeExito,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No se pudo exportar: $e'),
        backgroundColor: AppTheme.rojoClaro,
      ));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _compartir() async {
    if (_ultimoArchivo == null) {
      await _exportar(true);
      if (_ultimoArchivo == null) return;
    }
    await BackupService.instancia.compartirArchivo(
      _ultimoArchivo!,
      textoExtra: 'Lecturas de ${widget.propiedad.nombre} — AguaLuz HN',
    );
  }

  void _verVistaPrevia() {
    if (_ultimoContenido == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Exportá primero en JSON o CSV para ver la vista previa'),
      ));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.fondoCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.borde, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Vista previa · $_ultimoFormato', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.55),
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.fondoAlto, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    BackupService.instancia.vistaPrevia(_ultimoContenido!),
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.grisClaro),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime f) {
    final h = f.hour.toString().padLeft(2, '0');
    final m = f.minute.toString().padLeft(2, '0');
    return '${f.day}/${f.month}/${f.year} $h:$m';
  }

  Widget _boton(String label, IconData icon, Color color, VoidCallback onTap) => OutlinedButton.icon(
        onPressed: _cargando ? null : onTap,
        icon: Icon(icon, size: 15, color: color),
        label: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.4), width: 0.8),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = widget.propiedad;
    final fecha = BackupService.instancia.obtenerUltimaExportacion(p.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borde),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.verde.withValues(alpha: 0.2), AppTheme.verde.withValues(alpha: 0.05)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.folder_zip_rounded, color: AppTheme.verde, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(
                fecha != null ? 'Última exportación: ${_formatearFecha(fecha)}' : 'Sin exportar todavía',
                style: TextStyle(fontSize: 11, color: fecha != null ? AppTheme.verdeClaro : AppTheme.gris),
              ),
            ]),
          ),
          if (_cargando)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.verde)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _boton('JSON', Icons.data_object_rounded, AppTheme.cian, () => _exportar(true))),
          const SizedBox(width: 8),
          Expanded(child: _boton('CSV', Icons.table_chart_rounded, AppTheme.naranja, () => _exportar(false))),
          const SizedBox(width: 8),
          Expanded(child: _boton('Compartir', Icons.share_rounded, AppTheme.verde, _compartir)),
        ]),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: _verVistaPrevia,
            icon: const Icon(Icons.visibility_outlined, size: 16, color: AppTheme.gris),
            label: const Text('Vista previa', style: TextStyle(color: AppTheme.gris, fontSize: 12)),
          ),
        ),
      ]),
    );
  }
}