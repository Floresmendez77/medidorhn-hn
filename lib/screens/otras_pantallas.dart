import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import '../theme/app_theme.dart';
import '../models/modelos.dart';
import '../data/datos.dart';
import '../widgets/widgets_compartidos.dart';
import '../data/database_helper.dart';
import 'pantalla_reporte_pdf.dart';
import '../services/notification_service.dart';

// ============================================================
// PANTALLAS: Lecturas, Historial, Simulador,
//            Propiedades, Tips  v5.1 + Foto medidor
// ============================================================

class _AppBarPremium extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  const _AppBarPremium({required this.title, this.actions});
  @override Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
    title: title, actions: actions,
    backgroundColor: AppTheme.fondo,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    elevation: 0,
  );
}

Widget _label(String txt) => Text(txt,
  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.gris, letterSpacing: 1.4));

// ── LECTURAS ─────────────────────────────────────────────────
class PantallaLecturas extends StatefulWidget {
  const PantallaLecturas({super.key});
  @override State<PantallaLecturas> createState() => _PantallaLecturasState();
}
class _PantallaLecturasState extends State<PantallaLecturas> {
  Propiedad _prop = propiedades.first;
  TipoServicio _serv = TipoServicio.agua;
  final _formKey = GlobalKey<FormState>();
  final Map<TipoServicio, TextEditingController> _ctrls = {
    TipoServicio.agua: TextEditingController(),
    TipoServicio.luz:  TextEditingController(),
    TipoServicio.gas:  TextEditingController(),
  };
  String _mes = 'Jun'; int _anio = DateTime.now().year;

  List<int> get _aniosDisponibles {
    final anioMin = _prop.lecturas.isNotEmpty
        ? _prop.lecturas.map((l) => l.fecha.year).reduce((a, b) => a < b ? a : b)
        : DateTime.now().year;
    final anioMax = DateTime.now().year + 1;
    return List.generate(anioMax - anioMin + 1, (i) => anioMin + i);
  }
  File? _fotoMedidor;
  final _picker = ImagePicker();

  @override void dispose() { for (final c in _ctrls.values) { c.dispose(); } super.dispose(); }

  Future<void> _tomarFoto() async {
    final opcion = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.fondoCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.borde, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('Foto del medidor', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 8),
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.cian.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.camera_alt_rounded, color: AppTheme.cian)),
          title: const Text('Tomar foto', style: TextStyle(color: Colors.white)),
          subtitle: const Text('Abrí la cámara', style: TextStyle(color: AppTheme.gris, fontSize: 11)),
          onTap: () => Navigator.pop(context, ImageSource.camera),
        ),
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.naranja.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.photo_library_rounded, color: AppTheme.naranja)),
          title: const Text('Elegir de galería', style: TextStyle(color: Colors.white)),
          subtitle: const Text('Seleccioná una imagen existente', style: TextStyle(color: AppTheme.gris, fontSize: 11)),
          onTap: () => Navigator.pop(context, ImageSource.gallery),
        ),
        if (_fotoMedidor != null) ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.rojoBg, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.delete_outline_rounded, color: AppTheme.rojoClaro)),
          title: const Text('Quitar foto', style: TextStyle(color: AppTheme.rojoClaro)),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _fotoMedidor = null);
            Navigator.pop(context);
            _snack('Foto quitada', AppTheme.gris);
          },
        ),
        const SizedBox(height: 8),
      ])),
    );
    if (opcion == null) return;
    HapticFeedback.selectionClick();
    try {
      final picked = await _picker.pickImage(source: opcion, imageQuality: 80, maxWidth: 1200);
      if (!mounted || picked == null) return;
      // Copiar a directorio permanente para que no se pierda al limpiar caché
      final docDir = await getApplicationDocumentsDirectory();
      final fotosDir = Directory(p.join(docDir.path, 'medidor_fotos'));
      if (!await fotosDir.exists()) await fotosDir.create(recursive: true);
      final nombreArchivo = 'medidor_\${DateTime.now().millisecondsSinceEpoch}.jpg';
      final archivoFinal = await File(picked.path).copy(p.join(fotosDir.path, nombreArchivo));
      setState(() => _fotoMedidor = archivoFinal);
      _snack('✓ Foto adjunta', AppTheme.verdeExito);
    } catch (_) {
      if (!mounted) return;
      _snack(
        opcion == ImageSource.camera
            ? 'No se pudo abrir la cámara. Revisá los permisos de la app.'
            : 'No se pudo abrir la galería. Revisá los permisos de la app.',
        AppTheme.rojoClaro,
        dur: 3,
      );
    }
  }

  void _confirmar() async {
    if (!_formKey.currentState!.validate()) return;
    final txt = _ctrls[_serv]!.text.trim();
    final val = double.parse(txt);
    final lecturas = _prop.lecturasPorServicio(_serv);
    final consumo = lecturas.isNotEmpty ? val - lecturas.last.valor : null;
    // Validar mes duplicado
    final mesKey = '$_mes $_anio';
    final duplicado = lecturas.any((l) => l.mes == mesKey);
    if (duplicado) {
      _snack('Ya existe una lectura para $_mes $_anio en este servicio', AppTheme.rojoClaro, dur: 3);
      return;
    }
    if (consumo != null && consumo < 0) {
      _snack('Valor menor a la lectura anterior (${lecturas.last.valor.toStringAsFixed(1)})', AppTheme.rojoClaro);
      return;
    }
    final nuevaLectura = Lectura(
      mes: '$_mes $_anio',
      valor: val,
      tipo: _serv,
      fecha: DateTime(_anio, meses.indexOf(_mes) + 1, 1),
      fotoPath: _fotoMedidor?.path,
    );
    await DatabaseHelper.instancia.insertarLectura(_prop.id, nuevaLectura);
    setState(() {
      _prop.lecturas.add(nuevaLectura);
      _ctrls[_serv]!.clear();
      _fotoMedidor = null;
    });
    _snack(consumo != null ? '✓ Guardado. Consumo: ${consumo.toStringAsFixed(1)} ${_serv.unidad}' : '✓ Primera lectura guardada', AppTheme.verdeExito, dur: 3);
  }

  void _snack(String msg, Color color, {int dur = 2}) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: color, duration: Duration(seconds: dur),
    behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));

  Future<bool?> _confirmarBorrarLectura(Lectura l) => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppTheme.fondoCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [
        Icon(Icons.warning_amber_rounded, color: AppTheme.rojoClaro, size: 22),
        SizedBox(width: 8),
        Text('Eliminar lectura', style: TextStyle(fontSize: 16, color: Colors.white)),
      ]),
      content: RichText(text: TextSpan(
        style: const TextStyle(fontSize: 13, color: AppTheme.gris, height: 1.5),
        children: [
          const TextSpan(text: '¿Eliminar la lectura de '),
          TextSpan(text: l.mes, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          TextSpan(text: ' (${l.valor.toStringAsFixed(1)} ${l.tipo.unidad})?\n\nEsta acción no se puede deshacer.'),
        ],
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: AppTheme.gris))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rojoClaro, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );

  Future<void> _borrarLectura(Lectura l) async {
    final base = await DatabaseHelper.instancia.db;
    final rows = await base.query('lecturas',
      where: 'propiedad_id = ? AND mes = ? AND tipo = ?',
      whereArgs: [_prop.id, l.mes, l.tipo.name],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final id = rows.first['id'] as int;
      await DatabaseHelper.instancia.eliminarLectura(id);
    }
    // Eliminar foto del disco si existe
    if (l.fotoPath != null) {
      try {
        final archivo = File(l.fotoPath!);
        if (await archivo.exists()) await archivo.delete();
      } catch (_) {}
    }
    setState(() => _prop.lecturas.remove(l));
    _snack('Lectura de ${l.mes} eliminada', AppTheme.rojoClaro);
  }

  @override
  Widget build(BuildContext context) {
    final lecturas = _prop.lecturasPorServicio(_serv);
    final ultima = lecturas.isNotEmpty ? lecturas.last : null;
    final color = _serv.color;

    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: _AppBarPremium(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: AppTheme.cian.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.edit_note_rounded, color: AppTheme.cian, size: 15),
          ),
          const SizedBox(width: 10),
          const Text('Ingresar Lectura'),
        ]),
        actions: [
          DropdownButton<String>(value: _mes, dropdownColor: AppTheme.fondoCard, underline: const SizedBox(), style: const TextStyle(color: AppTheme.cian, fontSize: 12), items: meses.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(), onChanged: (v) => setState(() => _mes = v!)),
          const SizedBox(width: 4),
          DropdownButton<int>(value: _aniosDisponibles.contains(_anio) ? _anio : _aniosDisponibles.last, dropdownColor: AppTheme.fondoCard, underline: const SizedBox(), style: const TextStyle(color: AppTheme.cian, fontSize: 12), items: _aniosDisponibles.map((a) => DropdownMenuItem(value: a, child: Text('$a'))).toList(), onChanged: (v) => setState(() => _anio = v!)),
          const SizedBox(width: 12),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            DropdownButtonFormField<Propiedad>(
              value: _prop, dropdownColor: AppTheme.fondoCard,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.home_rounded, color: AppTheme.cian, size: 18), labelText: 'Propiedad'),
              items: propiedades.map((p) => DropdownMenuItem(value: p, child: Text(p.nombre, style: const TextStyle(color: Colors.white, fontSize: 14)))).toList(),
              onChanged: (p) => setState(() { _prop = p!; _serv = p.servicios.first; }),
              validator: (v) => v == null ? 'Seleccioná una propiedad' : null,
            ),
            const SizedBox(height: 16),

            Row(children: _prop.servicios.map((s) => Padding(padding: const EdgeInsets.only(right: 8), child: ServicioBadge(tipo: s, activo: _serv == s, onTap: () => setState(() => _serv = s)))).toList()),
            const SizedBox(height: 16),

            if (ultima != null) Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: Row(children: [
                Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(_serv.icono, color: color, size: 22)),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Última lectura — ${ultima.mes}', style: const TextStyle(fontSize: 11, color: AppTheme.gris)),
                  Text('${ultima.valor.toStringAsFixed(1)} ${_serv.unidad}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5)),
                ]),
              ]),
            ),

            // ── Campo de ingreso ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.fondoCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(_serv.icono, color: color, size: 14),
                  const SizedBox(width: 6),
                  Text('${_serv.emoji} ${_serv.nombre} — $_mes $_anio', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.blanco)),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: TextFormField(
                    controller: _ctrls[_serv],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color, letterSpacing: -1),
                    decoration: InputDecoration(
                      hintText: 'Nueva lectura',
                      hintStyle: TextStyle(color: color.withValues(alpha: 0.2), fontSize: 22, fontWeight: FontWeight.w600),
                      suffixText: _serv.unidad,
                      suffixStyle: const TextStyle(color: AppTheme.gris, fontSize: 14),
                      fillColor: Colors.transparent,
                      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Ingresá el valor del medidor';
                      if (double.tryParse(v.trim()) == null) return 'Solo números, por favor';
                      return null;
                    },
                  )),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _confirmar,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5))],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.black, size: 26),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),

                // ── FOTO DEL MEDIDOR ──────────────────────────
                GestureDetector(
                  onTap: _tomarFoto,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _fotoMedidor != null ? Colors.transparent : AppTheme.fondoAlto,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _fotoMedidor != null ? color.withValues(alpha: 0.4) : AppTheme.borde,
                        width: _fotoMedidor != null ? 1.5 : 1,
                      ),
                    ),
                    child: _fotoMedidor != null
                        ? Stack(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Image.file(_fotoMedidor!, width: double.infinity, height: 160, fit: BoxFit.cover),
                            ),
                            Positioned(top: 8, right: 8, child: Row(children: [
                              Tooltip(message: 'Cambiar foto', child: GestureDetector(
                                onTap: _tomarFoto,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                                  child: const Icon(Icons.cached_rounded, color: Colors.white, size: 16),
                                ),
                              )),
                              const SizedBox(width: 6),
                              Tooltip(message: 'Quitar foto', child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _fotoMedidor = null);
                                  _snack('Foto quitada', AppTheme.gris);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              )),
                            ])),
                            Positioned(bottom: 8, left: 8, child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.check_circle_rounded, color: color, size: 12),
                                const SizedBox(width: 4),
                                const Text('Foto adjunta', style: TextStyle(fontSize: 10, color: Colors.white)),
                              ]),
                            )),
                          ])
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.camera_alt_rounded, color: color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Adjuntar foto del medidor', style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
                                const Text('Opcional — como evidencia de la lectura', style: TextStyle(fontSize: 10, color: AppTheme.gris)),
                              ]),
                              const Spacer(),
                              Icon(Icons.chevron_right_rounded, color: AppTheme.gris, size: 18),
                            ]),
                          ),
                  ),
                ),
                if (_fotoMedidor != null) Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text('Tocá la foto para cambiarla', style: TextStyle(fontSize: 10, color: AppTheme.gris.withValues(alpha: 0.8))),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Historial rápido ──
            if (lecturas.length >= 2) ...[
              _label('ÚLTIMAS LECTURAS'),
              const SizedBox(height: 10),
              ...lecturas.reversed.take(5).toList().asMap().entries.map((mapEntry) {
                final l = mapEntry.value;
                final listIdx = mapEntry.key;
                final idx = lecturas.indexOf(l);
                final consumo = idx > 0 ? l.valor - lecturas[idx-1].valor : null;
                final prom = _prop.consumoPromedio(_serv);
                final esAlto = consumo != null && prom > 0 && consumo > prom * 1.2;
                return Dismissible(
                  key: ValueKey('${_prop.id}_${listIdx}_${l.mes}_${l.tipo.name}'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmarBorrarLectura(l),
                  onDismissed: (_) => _borrarLectura(l),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: AppTheme.rojoBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.rojoClaro.withValues(alpha: 0.3))),
                    child: const Icon(Icons.delete_outline_rounded, color: AppTheme.rojoClaro, size: 22),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.fondoCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: esAlto ? AppTheme.rojoClaro.withValues(alpha: 0.3) : AppTheme.borde),
                    ),
                    child: Row(children: [
                      // Thumbnail foto si existe
                      if (l.fotoPath != null) ...[
                        GestureDetector(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              backgroundColor: Colors.black,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(File(l.fotoPath!), fit: BoxFit.contain),
                              ),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(l.fotoPath!), width: 40, height: 40, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(l.mes, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                      const Spacer(),
                      Text('${l.valor.toStringAsFixed(1)} ${_serv.unidad}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                      if (consumo != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: esAlto ? AppTheme.rojoBg : AppTheme.verdeBg, borderRadius: BorderRadius.circular(8)),
                          child: Text('+${consumo.toStringAsFixed(1)}', style: TextStyle(fontSize: 11, color: esAlto ? AppTheme.rojoClaro : AppTheme.verdeClaro, fontWeight: FontWeight.w600)),
                        ),
                      ],
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final ok = await _confirmarBorrarLectura(l);
                          if (ok == true) _borrarLectura(l);
                        },
                        child: const Icon(Icons.delete_outline_rounded, color: AppTheme.rojoClaro, size: 18),
                      ),
                    ]),
                  ),
                );
              }),
            ],
          ]),
        ),
      ),
    );
  }
}

// ── HISTORIAL ─────────────────────────────────────────────────
class PantallaHistorial extends StatefulWidget {
  const PantallaHistorial({super.key});
  @override State<PantallaHistorial> createState() => _PantallaHistorialState();
}
class _PantallaHistorialState extends State<PantallaHistorial> {
  Propiedad _prop = propiedades.first;
  TipoServicio _serv = TipoServicio.agua;
  bool _modoLinea = false; // false = barras, true = líneas

  @override
  Widget build(BuildContext context) {
    final lecturas = _prop.lecturasPorServicio(_serv);
    final consumos = <double>[], etiquetas = <String>[];
    for (int i = 1; i < lecturas.length; i++) {
      consumos.add(lecturas[i].valor - lecturas[i-1].valor);
      etiquetas.add(lecturas[i].mes.split(' ').first);
    }
    final prom = _prop.consumoPromedio(_serv);
    final actual = consumos.isNotEmpty ? consumos.last : 0.0;
    final variacion = prom > 0 ? (actual - prom) / prom * 100 : 0.0;
    final sube = variacion > 0;

    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: _AppBarPremium(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: AppTheme.verdeClaro.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.bar_chart_rounded, color: AppTheme.verdeClaro, size: 15),
          ),
          const SizedBox(width: 10),
          const Text('Historial'),
        ]),
        actions: [Padding(padding: const EdgeInsets.only(right: 12), child: DropdownButton<Propiedad>(
          value: _prop, dropdownColor: AppTheme.fondoCard, underline: const SizedBox(),
          style: const TextStyle(color: AppTheme.cian, fontSize: 12),
          items: propiedades.map((p) => DropdownMenuItem(value: p, child: Text(p.nombre))).toList(),
          onChanged: (p) => setState(() { _prop = p!; _serv = p.servicios.first; }),
        ))],
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: _prop.servicios.map((s) => Padding(padding: const EdgeInsets.only(right: 8), child: ServicioBadge(tipo: s, activo: _serv == s, onTap: () => setState(() => _serv = s)))).toList()),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: MetricaCard(titulo: 'Este mes', valor: actual.toStringAsFixed(1), unidad: _serv.unidad, icono: _serv.icono, color: _serv.color, alerta: variacion > 20)),
          const SizedBox(width: 10),
          Expanded(child: MetricaCard(titulo: 'Promedio', valor: prom.toStringAsFixed(1), unidad: _serv.unidad, icono: Icons.bar_chart_rounded, color: AppTheme.cian)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: variacion > 20 ? AppTheme.rojoBg : variacion < -10 ? AppTheme.verdeBg : AppTheme.fondoCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: variacion > 20 ? AppTheme.rojoClaro.withValues(alpha: 0.3) : variacion < -10 ? AppTheme.verdeClaro.withValues(alpha: 0.3) : AppTheme.borde),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: (sube ? AppTheme.rojoClaro : AppTheme.verdeClaro).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(sube ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: variacion > 20 ? AppTheme.rojoClaro : AppTheme.verdeClaro, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(sube ? '+${variacion.toStringAsFixed(1)}% sobre el promedio' : '${variacion.toStringAsFixed(1)}% bajo el promedio',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: variacion > 20 ? AppTheme.rojoClaro : AppTheme.verdeClaro))),
          ]),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _label('${_serv.emoji} CONSUMO MENSUAL (${_serv.unidad})')),
            // Toggle barras / líneas
            GestureDetector(
              onTap: () => setState(() => _modoLinea = !_modoLinea),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _modoLinea ? _serv.color.withValues(alpha: 0.12) : AppTheme.fondoAlto,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _modoLinea ? _serv.color.withValues(alpha: 0.4) : AppTheme.borde),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_modoLinea ? Icons.show_chart_rounded : Icons.bar_chart_rounded,
                    color: _modoLinea ? _serv.color : AppTheme.gris, size: 16),
                  const SizedBox(width: 5),
                  Text(_modoLinea ? 'Línea' : 'Barras',
                    style: TextStyle(fontSize: 11, color: _modoLinea ? _serv.color : AppTheme.gris, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.fondoCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.borde)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_modoLinea ? 'Tendencia de consumo mensual' : 'Última barra = mes actual · Rojo = consumo alto',
              style: const TextStyle(fontSize: 10, color: AppTheme.gris)),
            const SizedBox(height: 14),
            consumos.isNotEmpty
              ? _modoLinea
                  ? GraficaLineas(valores: consumos, etiquetas: etiquetas, color: _serv.color, promedioLinea: prom)
                  : GraficaBarras(valores: consumos, etiquetas: etiquetas, color: _serv.color, promedioLinea: prom)
              : const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Sin datos suficientes', style: TextStyle(color: AppTheme.gris)))),
          ]),
        ),
        const SizedBox(height: 20),
        _label('DETALLE MENSUAL'),
        const SizedBox(height: 10),
        if (consumos.isEmpty)
          const Text('Necesitás al menos 2 lecturas.', style: TextStyle(color: AppTheme.gris, fontSize: 13))
        else ...List.generate(consumos.length, (i) {
          final idx = consumos.length - 1 - i;
          final c = consumos[idx];
          final esAlto = c > prom * 1.2; final esBajo = c < prom * 0.8;
          final factura = _serv == TipoServicio.luz ? calcularFacturaENEE(c).total : _serv == TipoServicio.agua ? calcularFacturaSANAA(c) : c * 28.5;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.fondoCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: esAlto ? AppTheme.rojoClaro.withValues(alpha: 0.3) : AppTheme.borde),
            ),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: _serv.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(_serv.emoji, style: const TextStyle(fontSize: 22)))),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(etiquetas[idx], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(lecturas[idx + 1].mes, style: const TextStyle(fontSize: 10, color: AppTheme.gris)),
              ]),
              const Spacer(),
              Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${c.toStringAsFixed(1)} ${_serv.unidad}', textAlign: TextAlign.right, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: esAlto ? AppTheme.rojoClaro : _serv.color)),
                Text('≈ L. ${factura.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: AppTheme.gris)),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: (esAlto ? AppTheme.rojoBg : esBajo ? AppTheme.verdeBg : AppTheme.fondoAlto), borderRadius: BorderRadius.circular(6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(esAlto ? Icons.arrow_upward_rounded : esBajo ? Icons.arrow_downward_rounded : Icons.remove_rounded, size: 9, color: esAlto ? AppTheme.rojoClaro : esBajo ? AppTheme.verdeClaro : AppTheme.gris),
                    const SizedBox(width: 2),
                    Text(esAlto ? '${((c/prom-1)*100).toStringAsFixed(0)}% alto' : esBajo ? '${((1-c/prom)*100).toStringAsFixed(0)}% bajo' : 'Normal',
                      style: TextStyle(fontSize: 9, color: esAlto ? AppTheme.rojoClaro : esBajo ? AppTheme.verdeClaro : AppTheme.gris, fontWeight: FontWeight.w600)),
                  ]),
                ),
                // Miniatura de foto si existe
                if (lecturas[idx + 1].fotoPath != null) ...[ 
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        backgroundColor: Colors.black,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(lecturas[idx + 1].fotoPath!), fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(lecturas[idx + 1].fotoPath!),
                        width: 48, height: 48, fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ])),
            ]),
          );
        }),
        const SizedBox(height: 24),
      ])),
    );
  }
}

// ── SIMULADOR ─────────────────────────────────────────────────
class PantallaSimulador extends StatefulWidget {
  const PantallaSimulador({super.key});
  @override State<PantallaSimulador> createState() => _PantallaSimuladorState();
}
class _PantallaSimuladorState extends State<PantallaSimulador> {
  final Map<Electrodomestico, double> _horas = {};

  @override
  Widget build(BuildContext context) {
    double kwhTotal = 0;
    for (final e in electrodomesticos) { kwhTotal += e.kwhMes(_horas[e] ?? 0, 30); }
    final factura = calcularFacturaENEE(kwhTotal);

    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: _AppBarPremium(title: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: AppTheme.naranja.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.bolt_rounded, color: AppTheme.naranja, size: 15),
        ),
        const SizedBox(width: 10),
        const Text('Simulador de Consumo'),
      ])),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0A1800), Color(0xFF070B16)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.verdeClaro.withValues(alpha: 0.2)),
            boxShadow: [BoxShadow(color: AppTheme.verdeClaro.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.luz.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.bolt_rounded, color: AppTheme.luz, size: 22)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('CONSUMO SIMULADO', style: TextStyle(fontSize: 9, color: AppTheme.gris, letterSpacing: 1.4)),
              Text('${kwhTotal.toStringAsFixed(0)} kWh/mes', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.blanco, letterSpacing: -0.5)),
              Text(factura.bloque, style: const TextStyle(fontSize: 10, color: AppTheme.gris)),
            ]),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('FACTURA ESTIMADA', style: TextStyle(fontSize: 9, color: AppTheme.gris, letterSpacing: 1.2)),
              Text('L. ${factura.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.verdeClaro, letterSpacing: -0.5)),
              const Text('ENEE + ISV + DAR', style: TextStyle(fontSize: 9, color: AppTheme.gris)),
            ]),
          ]),
        ),
        const SizedBox(height: 4),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: electrodomesticos.length,
          itemBuilder: (_, i) {
            final e = electrodomesticos[i];
            final horas = _horas[e] ?? 0.0;
            final kwh = e.kwhMes(horas, 30);
            final activo = horas > 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.fondoCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: activo ? AppTheme.luz.withValues(alpha: 0.22) : AppTheme.borde),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 42, height: 42, decoration: BoxDecoration(color: (activo ? AppTheme.luz : AppTheme.gris).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(e.emoji, style: const TextStyle(fontSize: 22)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.blanco)),
                    Text('${e.wattsPromedio}W · ${kwh.toStringAsFixed(1)} kWh/mes', style: const TextStyle(fontSize: 11, color: AppTheme.gris)),
                  ])),
                  if (activo) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.luzBg, borderRadius: BorderRadius.circular(10)),
                    child: Text('≈ L. ${e.costoMes(horas, 30).toStringAsFixed(0)}/mes', style: const TextStyle(fontSize: 11, color: AppTheme.luz, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  const Text('0h', style: TextStyle(fontSize: 10, color: AppTheme.gris)),
                  Expanded(child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    ),
                    child: Slider(
                      value: horas, min: 0, max: 24, divisions: 48,
                      activeColor: horas > 8 ? AppTheme.rojoClaro : AppTheme.luz,
                      inactiveColor: AppTheme.borde,
                      onChanged: (v) => setState(() => _horas[e] = v),
                    ),
                  )),
                  SizedBox(
                    width: 52,
                    child: Text('${horas.toStringAsFixed(1)}h/d', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, color: activo ? AppTheme.luz : AppTheme.gris, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ]),
            );
          },
        )),
      ]),
    );
  }
}

// ── PROPIEDADES ──────────────────────────────────────────────
class PantallaPropiedades extends StatefulWidget {
  const PantallaPropiedades({super.key});
  @override State<PantallaPropiedades> createState() => _PantallaPropiedadesState();
}
class _PantallaPropiedadesState extends State<PantallaPropiedades> {
  Future<bool?> _confirmarBorrar(Propiedad p) => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppTheme.fondoCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [
        Icon(Icons.warning_amber_rounded, color: AppTheme.rojoClaro, size: 22),
        SizedBox(width: 8),
        Text('Eliminar propiedad', style: TextStyle(fontSize: 16, color: Colors.white)),
      ]),
      content: RichText(text: TextSpan(
        style: const TextStyle(fontSize: 13, color: AppTheme.gris, height: 1.5),
        children: [
          const TextSpan(text: '¿Seguro que querés eliminar '),
          TextSpan(text: p.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const TextSpan(text: '?\n\nSe borrarán también todas sus lecturas. Esta acción no se puede deshacer.'),
        ],
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: AppTheme.gris))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rojoClaro, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );

  Future<void> _borrarPropiedad(Propiedad p) async {
    await DatabaseHelper.instancia.eliminarPropiedad(p.id);
    setState(() => propiedades.remove(p));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${p.nombre} eliminada'),
      backgroundColor: AppTheme.rojoClaro,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _editar(Propiedad p) {
    final formKey = GlobalKey<FormState>();
    final n = TextEditingController(text: p.nombre);
    final d = TextEditingController(text: p.direccion);
    final c = TextEditingController(text: p.colonia);
    final sel = <TipoServicio>{...p.servicios};
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppTheme.fondoCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StatefulBuilder(builder: (ctx, set) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 28),
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.borde, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.naranja.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.edit_rounded, color: AppTheme.naranja, size: 20)),
              const SizedBox(width: 10),
              const Text('Editar Propiedad', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, color: AppTheme.gris, size: 20), onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 18),
            _campo(n, 'Nombre (ej: Casa Principal)', Icons.home_rounded, requerido: true),
            const SizedBox(height: 10),
            _campo(d, 'Dirección', Icons.location_on_rounded, requerido: true),
            const SizedBox(height: 10),
            _campo(c, 'Colonia / Ciudad', Icons.map_rounded, requerido: true),
            const SizedBox(height: 16),
            const Text('SERVICIOS', style: TextStyle(color: AppTheme.gris, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Row(children: TipoServicio.values.map((s) => Padding(padding: const EdgeInsets.only(right: 8), child: ServicioBadge(tipo: s, activo: sel.contains(s), onTap: () => set(() => sel.contains(s) ? (sel.length > 1 ? sel.remove(s) : null) : sel.add(s))))).toList()),
            const SizedBox(height: 22),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded, size: 18), label: const Text('Guardar cambios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.naranja, foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final editada = Propiedad(
                  id: p.id,
                  nombre: n.text.trim(),
                  direccion: d.text.trim(),
                  colonia: c.text.trim(),
                  servicios: sel.toList(),
                  lecturas: p.lecturas,
                );
                await DatabaseHelper.instancia.actualizarPropiedad(editada);
                final idx = propiedades.indexWhere((x) => x.id == p.id);
                setState(() => propiedades[idx] = editada);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${editada.nombre} actualizada ✓'),
                  backgroundColor: AppTheme.naranja,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
              },
            )),
          ]),
        ),
      )),
    );
  }

  void _agregar() {
    final _formKeyProp = GlobalKey<FormState>();
    final n = TextEditingController(), d = TextEditingController(), c = TextEditingController();
    final sel = <TipoServicio>{TipoServicio.agua, TipoServicio.luz};
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppTheme.fondoCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StatefulBuilder(builder: (ctx, set) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 28),
        child: Form(
          key: _formKeyProp,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.borde, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.cian.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.add_home_rounded, color: AppTheme.cian, size: 20)),
              const SizedBox(width: 10),
              const Text('Nueva Propiedad', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, color: AppTheme.gris, size: 20), onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 18),
            _campo(n, 'Nombre (ej: Casa Principal)', Icons.home_rounded, requerido: true),
            const SizedBox(height: 10),
            _campo(d, 'Dirección', Icons.location_on_rounded, requerido: true),
            const SizedBox(height: 10),
            _campo(c, 'Colonia / Ciudad', Icons.map_rounded, requerido: true),
            const SizedBox(height: 16),
            const Text('SERVICIOS', style: TextStyle(color: AppTheme.gris, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Row(children: TipoServicio.values.map((s) => Padding(padding: const EdgeInsets.only(right: 8), child: ServicioBadge(tipo: s, activo: sel.contains(s), onTap: () => set(() => sel.contains(s) ? (sel.length > 1 ? sel.remove(s) : null) : sel.add(s))))).toList()),
            const SizedBox(height: 22),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded, size: 18), label: const Text('Guardar propiedad'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () async {
                if (!_formKeyProp.currentState!.validate()) return;
                final nueva = Propiedad(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  nombre: n.text.trim(),
                  direccion: d.text.trim(),
                  colonia: c.text.trim(),
                  servicios: sel.toList(),
                  lecturas: [],
                );
                await DatabaseHelper.instancia.insertarPropiedad(nueva);
                setState(() => propiedades.add(nueva));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${nueva.nombre} agregada ✓'), backgroundColor: AppTheme.verdeExito, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
              },
            )),
          ]),
        ),
      )),
    );
  }

  Widget _campo(TextEditingController c, String h, IconData i, {bool requerido = false}) => TextFormField(
    controller: c,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(hintText: h, prefixIcon: Icon(i, color: AppTheme.cian, size: 18)),
    validator: requerido ? (v) => (v == null || v.trim().isEmpty) ? 'Este campo es requerido' : null : null,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.fondo,
    appBar: _AppBarPremium(
      title: Row(children: [
        Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: AppTheme.cian.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.home_rounded, color: AppTheme.cian, size: 15)),
        const SizedBox(width: 10),
        const Text('Mis Propiedades'),
      ]),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaReportePDF())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.rojoClaro.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.rojoClaro.withValues(alpha: 0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.picture_as_pdf_rounded, color: AppTheme.rojoClaro, size: 16),
                SizedBox(width: 5),
                Text('PDF', style: TextStyle(color: AppTheme.rojoClaro, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
      ],
    ),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      ...propiedades.map((p) {
        final score = p.scoreEficiencia();
        return Dismissible(
          key: ValueKey(p.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmarBorrar(p),
          onDismissed: (_) => _borrarPropiedad(p),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.rojoBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.rojoClaro.withValues(alpha: 0.3)),
            ),
            child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.delete_outline_rounded, color: AppTheme.rojoClaro, size: 28),
              SizedBox(height: 4),
              Text('Eliminar', style: TextStyle(fontSize: 10, color: AppTheme.rojoClaro, fontWeight: FontWeight.w600)),
            ]),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.fondoCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.borde)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 46, height: 46, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.cian.withValues(alpha: 0.2), AppTheme.azul.withValues(alpha: 0.08)]), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.home_rounded, color: AppTheme.cian, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.nombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('${p.direccion} · ${p.colonia}', style: const TextStyle(fontSize: 11, color: AppTheme.gris), overflow: TextOverflow.ellipsis),
                ])),
                ScoreEficiencia(score: score),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _editar(p),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.naranja.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.naranja.withValues(alpha: 0.3))),
                    child: const Icon(Icons.edit_rounded, color: AppTheme.naranja, size: 18),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () async {
                    final ok = await _confirmarBorrar(p);
                    if (ok == true) _borrarPropiedad(p);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.rojoBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.rojoClaro.withValues(alpha: 0.3))),
                    child: const Icon(Icons.delete_outline_rounded, color: AppTheme.rojoClaro, size: 18),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                ...p.servicios.map((s) => Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: s.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(s.icono, size: 12, color: s.color), const SizedBox(width: 5), Text(s.nombre, style: TextStyle(fontSize: 10, color: s.color, fontWeight: FontWeight.w600))]),
                )),
                const Spacer(),
                Text('${p.lecturas.length} lecturas', style: const TextStyle(fontSize: 11, color: AppTheme.gris)),
              ]),
            ]),
          ),
        );
      }),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _agregar,
        icon: const Icon(Icons.add_rounded, color: AppTheme.cian),
        label: const Text('Agregar propiedad', style: TextStyle(color: AppTheme.cian)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.cian, width: 0.8), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
      const SizedBox(height: 24),
    ]),
  );
}

// ── TIPS ─────────────────────────────────────────────────────
class PantallaTips extends StatefulWidget {
  const PantallaTips({super.key});
  @override State<PantallaTips> createState() => _PantallaTipsState();
}
class _PantallaTipsState extends State<PantallaTips> {
  TipoServicio? _filtro;
  @override
  Widget build(BuildContext context) {
    final lista = _filtro == null ? tips : tips.where((t) => t.tipo == _filtro).toList();
    final ahorro = lista.fold(0, (s, t) => s + t.ahorroEstimado);
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: _AppBarPremium(title: Row(children: [
        Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: AppTheme.verdeClaro.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.verdeClaro, size: 15)),
        const SizedBox(width: 10),
        const Text('Tips de Ahorro 🇭🇳'),
      ])),
      body: Column(children: [
        Container(
          color: AppTheme.fondo,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(children: [
            GestureDetector(
              onTap: () => setState(() => _filtro = null),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _filtro == null ? AppTheme.cian.withValues(alpha: 0.12) : Colors.transparent,
                  border: Border.all(color: _filtro == null ? AppTheme.cian : AppTheme.borde, width: _filtro == null ? 1.5 : 0.8),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text('Todos', style: TextStyle(fontSize: 12, color: _filtro == null ? AppTheme.cian : AppTheme.gris, fontWeight: _filtro == null ? FontWeight.w700 : FontWeight.w400)),
              ),
            ),
            const SizedBox(width: 8),
            ...TipoServicio.values.map((s) => Padding(padding: const EdgeInsets.only(right: 8), child: ServicioBadge(tipo: s, activo: _filtro == s, onTap: () => setState(() => _filtro = _filtro == s ? null : s)))),
          ]),
        ),
        if (ahorro > 0) Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.verdeBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.verdeClaro.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.verdeClaro.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.savings_outlined, color: AppTheme.verdeClaro, size: 17)),
            const SizedBox(width: 10),
            Expanded(child: Text('Aplicando estos tips ahorrás hasta L. $ahorro/mes', style: const TextStyle(fontSize: 12, color: AppTheme.verdeClaro, fontWeight: FontWeight.w500))),
          ]),
        ),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemCount: lista.length,
          itemBuilder: (_, i) => TipCard(tip: lista[i]),
        )),
      ]),
    );
  }
}

// ── ALERTAS ──────────────────────────────────────────────────
// Pantalla dedicada que agrupa TODAS las alertas activas
// de todas las propiedades registradas.
//
// Tipos de alerta generados desde los modelos:
//   • Consumo alto (>20% sobre el promedio) — por servicio
//   • Posible fuga de agua (consumo mínimo >= 80% promedio)
//   • Sin lecturas (propiedad sin datos aún)
// ─────────────────────────────────────────────────────────────

enum _TipoAlerta { consumoAlto, fuga, sinLecturas }

class _Alerta {
  final _TipoAlerta tipo;
  final Propiedad propiedad;
  final TipoServicio? servicio;
  final double? consumoActual;
  final double? consumoPromedio;

  const _Alerta({
    required this.tipo,
    required this.propiedad,
    this.servicio,
    this.consumoActual,
    this.consumoPromedio,
  });

  String get titulo {
    switch (tipo) {
      case _TipoAlerta.consumoAlto:
        return 'Consumo alto de ${servicio!.nombre}';
      case _TipoAlerta.fuga:
        return 'Posible fuga de agua';
      case _TipoAlerta.sinLecturas:
        return 'Sin lecturas registradas';
    }
  }

  String get descripcion {
    switch (tipo) {
      case _TipoAlerta.consumoAlto:
        final pct = consumoPromedio! > 0
            ? ((consumoActual! - consumoPromedio!) / consumoPromedio! * 100).toStringAsFixed(0)
            : '—';
        return 'Este mes: ${consumoActual!.toStringAsFixed(1)} ${servicio!.unidad} '
            '(+$pct% sobre el promedio de ${consumoPromedio!.toStringAsFixed(1)} ${servicio!.unidad})';
      case _TipoAlerta.fuga:
        return 'El consumo mínimo de los últimos 3 meses se mantiene elevado. '
            'Revisá llaves, tuberías y sanitarios.';
      case _TipoAlerta.sinLecturas:
        return 'Esta propiedad no tiene lecturas aún. '
            'Registrá la primera lectura para comenzar el monitoreo.';
    }
  }

  String get recomendacion {
    switch (tipo) {
      case _TipoAlerta.consumoAlto:
        if (servicio == TipoServicio.agua) return 'Revisá llaves abiertas, riego excesivo o fugas.';
        if (servicio == TipoServicio.luz)  return 'Revisá electrodomésticos encendidos innecesariamente.';
        return 'Revisá el uso de gas en hornillas y calentador.';
      case _TipoAlerta.fuga:
        return 'Cerrá la llave principal y verificá si el medidor sigue girando.';
      case _TipoAlerta.sinLecturas:
        return 'Andá a la sección Lecturas y registrá el valor del medidor.';
    }
  }

  Color get color {
    switch (tipo) {
      case _TipoAlerta.consumoAlto: return servicio?.color ?? AppTheme.naranja;
      case _TipoAlerta.fuga:        return AppTheme.agua;
      case _TipoAlerta.sinLecturas: return AppTheme.gris;
    }
  }

  Color get colorBg {
    switch (tipo) {
      case _TipoAlerta.consumoAlto:
        if (servicio == TipoServicio.agua) return AppTheme.aguaBg;
        if (servicio == TipoServicio.luz)  return AppTheme.luzBg;
        return AppTheme.gasBg;
      case _TipoAlerta.fuga:        return AppTheme.aguaBg;
      case _TipoAlerta.sinLecturas: return AppTheme.fondoAlto;
    }
  }

  IconData get icono {
    switch (tipo) {
      case _TipoAlerta.consumoAlto: return Icons.trending_up_rounded;
      case _TipoAlerta.fuga:        return Icons.water_drop_rounded;
      case _TipoAlerta.sinLecturas: return Icons.inbox_rounded;
    }
  }

  String get etiqueta {
    switch (tipo) {
      case _TipoAlerta.consumoAlto: return 'CONSUMO ALTO';
      case _TipoAlerta.fuga:        return 'POSIBLE FUGA';
      case _TipoAlerta.sinLecturas: return 'SIN DATOS';
    }
  }
}

// ── Genera todas las alertas de todas las propiedades ──
List<_Alerta> _generarAlertas() {
  final alertas = <_Alerta>[];
  for (final p in propiedades) {
    // Sin lecturas en absoluto
    if (p.lecturas.isEmpty) {
      alertas.add(_Alerta(tipo: _TipoAlerta.sinLecturas, propiedad: p));
      continue;
    }
    // Consumo alto por servicio
    for (final s in p.servicios) {
      if (p.alertaConsumo(s)) {
        alertas.add(_Alerta(
          tipo: _TipoAlerta.consumoAlto,
          propiedad: p,
          servicio: s,
          consumoActual: p.consumoActual(s),
          consumoPromedio: p.consumoPromedio(s),
        ));
      }
    }
    // Posible fuga de agua
    if (p.servicios.contains(TipoServicio.agua) && p.posibleFugaAgua()) {
      alertas.add(_Alerta(tipo: _TipoAlerta.fuga, propiedad: p));
    }
  }
  return alertas;
}

class PantallaAlertas extends StatefulWidget {
  const PantallaAlertas({super.key});
  @override
  State<PantallaAlertas> createState() => _PantallaAlertasState();
}

class _PantallaAlertasState extends State<PantallaAlertas> {
  final Set<int> _descartadas = {};
  _TipoAlerta? _filtro;

  @override
  void initState() {
    super.initState();
    // Enviar notificaciones push para alertas activas al abrir la pantalla
    _dispararNotificaciones();
  }

  Future<void> _dispararNotificaciones() async {
    final alertas = _generarAlertas();
    for (final a in alertas) {
      if (a.tipo == _TipoAlerta.consumoAlto && a.servicio != null) {
        final pct = a.consumoPromedio != null && a.consumoPromedio! > 0
            ? (a.consumoActual! - a.consumoPromedio!) / a.consumoPromedio! * 100
            : 0.0;
        await NotificationService.instancia.alertaConsumoAlto(
          nombrePropiedad: a.propiedad.nombre,
          servicio: a.servicio!.nombre,
          emoji: a.servicio!.emoji,
          porcentaje: pct,
        );
      } else if (a.tipo == _TipoAlerta.fuga) {
        await NotificationService.instancia.recordatorioServicio(
          nombrePropiedad: a.propiedad.nombre,
          servicio: 'agua',
          emoji: '💧',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todas = _generarAlertas();
    final visibles = todas
        .asMap()
        .entries
        .where((e) => !_descartadas.contains(e.key))
        .where((e) => _filtro == null || e.value.tipo == _filtro)
        .toList();

    final hayConsumo   = todas.any((a) => a.tipo == _TipoAlerta.consumoAlto);
    final hayFuga      = todas.any((a) => a.tipo == _TipoAlerta.fuga);
    final haySinDatos  = todas.any((a) => a.tipo == _TipoAlerta.sinLecturas);

    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: _AppBarPremium(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.rojoClaro.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_active_rounded, color: AppTheme.rojoClaro, size: 15),
          ),
          const SizedBox(width: 10),
          const Text('Alertas'),
          if (visibles.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppTheme.rojoClaro, borderRadius: BorderRadius.circular(20)),
              child: Text('${visibles.length}',
                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        ]),
        actions: [
          if (visibles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: () => setState(() => _descartadas.addAll(todas.asMap().keys)),
                child: const Text('Limpiar', style: TextStyle(color: AppTheme.gris, fontSize: 12)),
              ),
            ),
        ],
      ),
      body: Column(children: [

        // ── Resumen rápido ──────────────────────────────────
        _ResumenAlertas(total: todas.length - _descartadas.length, todas: todas),

        // ── Filtros ─────────────────────────────────────────
        if (todas.length > 1)
          Container(
            color: AppTheme.fondo,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _FiltroChip(label: 'Todas', activo: _filtro == null, onTap: () => setState(() => _filtro = null)),
                if (hayConsumo)  const SizedBox(width: 8),
                if (hayConsumo)  _FiltroChip(label: '📈 Consumo', activo: _filtro == _TipoAlerta.consumoAlto, color: AppTheme.naranja, onTap: () => setState(() => _filtro = _filtro == _TipoAlerta.consumoAlto ? null : _TipoAlerta.consumoAlto)),
                if (hayFuga)     const SizedBox(width: 8),
                if (hayFuga)     _FiltroChip(label: '💧 Fuga', activo: _filtro == _TipoAlerta.fuga, color: AppTheme.agua, onTap: () => setState(() => _filtro = _filtro == _TipoAlerta.fuga ? null : _TipoAlerta.fuga)),
                if (haySinDatos) const SizedBox(width: 8),
                if (haySinDatos) _FiltroChip(label: '📭 Sin datos', activo: _filtro == _TipoAlerta.sinLecturas, color: AppTheme.gris, onTap: () => setState(() => _filtro = _filtro == _TipoAlerta.sinLecturas ? null : _TipoAlerta.sinLecturas)),
              ]),
            ),
          ),

        // ── Lista de alertas ────────────────────────────────
        Expanded(
          child: visibles.isEmpty
              ? _PantallaVaciaAlertas(hayDescartadas: _descartadas.isNotEmpty, onRestaurar: () => setState(() => _descartadas.clear()))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: visibles.length,
                  itemBuilder: (_, i) {
                    final entry = visibles[i];
                    return Dismissible(
                      key: ValueKey('alerta_${entry.key}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => setState(() => _descartadas.add(entry.key)),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.rojoBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.rojoClaro.withValues(alpha: 0.3)),
                        ),
                        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.check_circle_outline_rounded, color: AppTheme.rojoClaro, size: 26),
                          SizedBox(height: 4),
                          Text('Descartar', style: TextStyle(fontSize: 10, color: AppTheme.rojoClaro, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                      child: _CardAlerta(alerta: entry.value),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

// ── Resumen numérico en la parte superior ─────────────────────
class _ResumenAlertas extends StatelessWidget {
  final int total;
  final List<_Alerta> todas;
  const _ResumenAlertas({required this.total, required this.todas});

  @override
  Widget build(BuildContext context) {
    final nAlto  = todas.where((a) => a.tipo == _TipoAlerta.consumoAlto).length;
    final nFuga  = todas.where((a) => a.tipo == _TipoAlerta.fuga).length;
    final nVacio = todas.where((a) => a.tipo == _TipoAlerta.sinLecturas).length;

    if (total == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.rojoBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.rojoClaro.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: AppTheme.rojoClaro.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.warning_amber_rounded, color: AppTheme.rojoClaro, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$total alerta${total != 1 ? 's' : ''} activa${total != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 3),
          Wrap(spacing: 10, children: [
            if (nAlto  > 0) Text('$nAlto consumo alto', style: const TextStyle(fontSize: 11, color: AppTheme.naranja)),
            if (nFuga  > 0) Text('$nFuga fuga${nFuga > 1 ? 's' : ''}', style: const TextStyle(fontSize: 11, color: AppTheme.agua)),
            if (nVacio > 0) Text('$nVacio sin datos', style: const TextStyle(fontSize: 11, color: AppTheme.gris)),
          ]),
        ])),
      ]),
    );
  }
}

// ── Card individual de alerta ──────────────────────────────────
class _CardAlerta extends StatefulWidget {
  final _Alerta alerta;
  const _CardAlerta({required this.alerta});
  @override State<_CardAlerta> createState() => _CardAlertaState();
}
class _CardAlertaState extends State<_CardAlerta> {
  bool _expandida = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.alerta;
    return GestureDetector(
      onTap: () => setState(() => _expandida = !_expandida),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: a.colorBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: a.color.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: a.color.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Cabecera
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: a.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
              child: Icon(a.icono, color: a.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: a.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(a.etiqueta, style: TextStyle(fontSize: 9, color: a.color, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(a.titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ])),
            Icon(_expandida ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: AppTheme.gris, size: 22),
          ]),

          // Propiedad
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.home_rounded, size: 13, color: AppTheme.gris),
            const SizedBox(width: 5),
            Text('${a.propiedad.nombre}', style: const TextStyle(fontSize: 12, color: AppTheme.gris)),
            const SizedBox(width: 6),
            Text('· ${a.propiedad.colonia}', style: const TextStyle(fontSize: 12, color: AppTheme.grisOscuro)),
          ]),

          // Detalle expandible
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 14),
              Container(height: 1, color: a.color.withValues(alpha: 0.15)),
              const SizedBox(height: 12),

              // Descripción
              Text(a.descripcion, style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5)),
              const SizedBox(height: 12),

              // Barra de consumo (solo para consumo alto)
              if (a.tipo == _TipoAlerta.consumoAlto && a.consumoPromedio! > 0) ...[
                _BarraConsumo(actual: a.consumoActual!, promedio: a.consumoPromedio!, color: a.color),
                const SizedBox(height: 12),
              ],

              // Recomendación
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.fondoAlto,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: a.color.withValues(alpha: 0.2)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.tips_and_updates_outlined, color: a.color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(a.recomendacion,
                      style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4))),
                ]),
              ),
            ]),
            crossFadeState: _expandida ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ]),
      ),
    );
  }
}

// ── Barra visual actual vs promedio ───────────────────────────
class _BarraConsumo extends StatelessWidget {
  final double actual, promedio;
  final Color color;
  const _BarraConsumo({required this.actual, required this.promedio, required this.color});

  @override
  Widget build(BuildContext context) {
    final maxVal = actual > promedio ? actual : promedio;
    final pctActual  = actual  / maxVal;
    final pctProm    = promedio / maxVal;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('COMPARATIVA DE CONSUMO'),
      const SizedBox(height: 8),
      _Barra(label: 'Este mes', valor: actual, pct: pctActual, color: color),
      const SizedBox(height: 6),
      _Barra(label: 'Promedio', valor: promedio, pct: pctProm, color: AppTheme.gris),
    ]);
  }
}

class _Barra extends StatelessWidget {
  final String label;
  final double valor, pct;
  final Color color;
  const _Barra({required this.label, required this.valor, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    SizedBox(width: 68, child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.gris))),
    Expanded(child: Stack(children: [
      Container(height: 8, decoration: BoxDecoration(color: AppTheme.fondoAlto, borderRadius: BorderRadius.circular(4))),
      FractionallySizedBox(widthFactor: pct, child: Container(
        height: 8,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)]),
      )),
    ])),
    const SizedBox(width: 8),
    SizedBox(width: 44, child: Text(valor.toStringAsFixed(1), textAlign: TextAlign.right,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700))),
  ]);
}

// ── Chip de filtro ─────────────────────────────────────────────
class _FiltroChip extends StatelessWidget {
  final String label;
  final bool activo;
  final Color color;
  final VoidCallback onTap;
  const _FiltroChip({required this.label, required this.activo, this.color = AppTheme.cian, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: activo ? color.withValues(alpha: 0.12) : Colors.transparent,
        border: Border.all(color: activo ? color : AppTheme.borde, width: activo ? 1.5 : 0.8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(label, style: TextStyle(
          fontSize: 12,
          color: activo ? color : AppTheme.gris,
          fontWeight: activo ? FontWeight.w700 : FontWeight.w400)),
    ),
  );
}

// ── Estado vacío ───────────────────────────────────────────────
class _PantallaVaciaAlertas extends StatelessWidget {
  final bool hayDescartadas;
  final VoidCallback onRestaurar;
  const _PantallaVaciaAlertas({required this.hayDescartadas, required this.onRestaurar});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppTheme.verdeBg,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.verdeClaro.withValues(alpha: 0.3), width: 1.5),
          ),
          child: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.verdeClaro, size: 40),
        ),
        const SizedBox(height: 20),
        const Text('Todo bajo control', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 8),
        const Text('No hay alertas activas en este momento.\nTus consumos están dentro de rangos normales.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.gris, height: 1.5)),
        if (hayDescartadas) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onRestaurar,
            icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.cian),
            label: const Text('Restaurar descartadas', style: TextStyle(color: AppTheme.cian, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.cian, width: 0.8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ]),
    ),
  );
}