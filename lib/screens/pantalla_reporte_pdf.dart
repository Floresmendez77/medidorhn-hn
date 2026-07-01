import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme/app_theme.dart';
import '../models/modelos.dart';
import '../data/datos.dart';

// ============================================================
// PANTALLA REPORTE PDF — AguaLuz HN
// Genera y comparte un reporte de consumo por propiedad
// ============================================================

class PantallaReportePDF extends StatefulWidget {
  const PantallaReportePDF({super.key});
  @override
  State<PantallaReportePDF> createState() => _PantallaReportePDFState();
}

class _PantallaReportePDFState extends State<PantallaReportePDF> {
  Propiedad? _propSel;
  TipoServicio _serv = TipoServicio.agua;
  bool _generando = false;

  @override
  void initState() {
    super.initState();
    if (propiedades.isNotEmpty) _propSel = propiedades.first;
  }

  // ── Genera el PDF ──────────────────────────────────────────
  Future<void> _generarYCompartir() async {
    if (_propSel == null) return;
    setState(() => _generando = true);

    try {
      final pdf = pw.Document();
      final prop = _propSel!;
      final lecturas = prop.lecturasPorServicio(_serv);

      // Colores del PDF
      final colorPrimario = PdfColor.fromHex('#00E5FF');
      final colorFondo    = PdfColor.fromHex('#070B16');
      final colorCard     = PdfColor.fromHex('#0D1526');
      final colorTexto    = PdfColor.fromHex('#F0F6FF');
      final colorGris     = PdfColor.fromHex('#7A90A8');
      final colorVerde    = PdfColor.fromHex('#00E676');
      final colorRojo     = PdfColor.fromHex('#FF5252');

      // Consumos calculados
      final consumos = <double>[];
      final etiquetas = <String>[];
      for (int i = 1; i < lecturas.length; i++) {
        consumos.add(lecturas[i].valor - lecturas[i - 1].valor);
        etiquetas.add(lecturas[i].mes);
      }
      final prom = prop.consumoPromedio(_serv);
      final actual = consumos.isNotEmpty ? consumos.last : 0.0;
      final factura = prop.facturaEstimada(_serv);
      final score = prop.scoreEficiencia();

      // Logo desde assets
      pw.ImageProvider? logo;
      try {
        final logoData = await rootBundle.load('assets/logomedidorhn.png');
        logo = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (_) {}

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.robotoRegular(),
          bold: await PdfGoogleFonts.robotoBold(),
        ),
        build: (ctx) => [

          // ── ENCABEZADO ──────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: colorFondo,
              borderRadius: pw.BorderRadius.circular(16),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Row(children: [
                    if (logo != null) ...[
                      pw.Image(logo, width: 36, height: 36),
                      pw.SizedBox(width: 10),
                    ],
                    pw.Text('AguaLuz HN',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: colorPrimario)),
                  ]),
                  pw.SizedBox(height: 4),
                  pw.Text('Reporte de Consumo — ${_serv.nombre}',
                    style: pw.TextStyle(fontSize: 12, color: colorGris)),
                  pw.SizedBox(height: 2),
                  pw.Text('Generado: ${_fechaHoy()}',
                    style: pw.TextStyle(fontSize: 10, color: colorGris)),
                ]),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: colorCard,
                    borderRadius: pw.BorderRadius.circular(10),
                    border: pw.Border.all(color: colorPrimario, width: 0.5),
                  ),
                  child: pw.Column(children: [
                    pw.Text('Score', style: pw.TextStyle(fontSize: 9, color: colorGris)),
                    pw.Text('$score/100',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold,
                        color: score >= 70 ? colorVerde : score >= 50 ? colorPrimario : colorRojo)),
                    pw.Text('Eficiencia', style: pw.TextStyle(fontSize: 9, color: colorGris)),
                  ]),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // ── DATOS DE LA PROPIEDAD ────────────────────────
          pw.Text('PROPIEDAD', style: pw.TextStyle(fontSize: 9, color: colorGris, letterSpacing: 1.5)),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: colorCard,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(children: [
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(prop.nombre,
                  style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: colorTexto)),
                pw.SizedBox(height: 3),
                pw.Text('${prop.direccion} · ${prop.colonia}',
                  style: pw.TextStyle(fontSize: 11, color: colorGris)),
              ])),
              pw.Text('${prop.lecturas.length} lecturas totales',
                style: pw.TextStyle(fontSize: 10, color: colorGris)),
            ]),
          ),

          pw.SizedBox(height: 16),

          // ── RESUMEN DE CONSUMO ───────────────────────────
          pw.Text('RESUMEN DEL MES', style: pw.TextStyle(fontSize: 9, color: colorGris, letterSpacing: 1.5)),
          pw.SizedBox(height: 6),
          pw.Row(children: [
            _pdfMetrica('Consumo actual', '${actual.toStringAsFixed(1)} ${_serv.unidad}',
              colorPrimario, colorCard, colorTexto, colorGris),
            pw.SizedBox(width: 10),
            _pdfMetrica('Promedio mensual', '${prom.toStringAsFixed(1)} ${_serv.unidad}',
              colorVerde, colorCard, colorTexto, colorGris),
            pw.SizedBox(width: 10),
            _pdfMetrica('Factura estimada', 'L. ${factura.toStringAsFixed(0)}',
              colorRojo, colorCard, colorTexto, colorGris),
          ]),

          pw.SizedBox(height: 16),

          // ── TABLA DE LECTURAS ────────────────────────────
          if (lecturas.isNotEmpty) ...[
            pw.Text('HISTORIAL DE LECTURAS', style: pw.TextStyle(fontSize: 9, color: colorGris, letterSpacing: 1.5)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromHex('#1A2B44'), width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: colorFondo),
                  children: [
                    _celdaHeader('Mes', colorPrimario),
                    _celdaHeader('Lectura (${_serv.unidad})', colorPrimario),
                    _celdaHeader('Consumo (${_serv.unidad})', colorPrimario),
                    _celdaHeader('Estado', colorPrimario),
                  ],
                ),
                // Filas
                ...lecturas.asMap().entries.map((entry) {
                  final i = entry.key;
                  final l = entry.value;
                  final consumo = i > 0 ? l.valor - lecturas[i - 1].valor : null;
                  final esAlto = consumo != null && prom > 0 && consumo > prom * 1.2;
                  final esBajo = consumo != null && prom > 0 && consumo < prom * 0.8;
                  final bgColor = i % 2 == 0 ? colorCard : PdfColor.fromHex('#0A1020');
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bgColor),
                    children: [
                      _celda(l.mes, colorTexto),
                      _celda(l.valor.toStringAsFixed(1), colorTexto),
                      _celda(consumo != null ? consumo.toStringAsFixed(1) : '—',
                        consumo != null ? (esAlto ? colorRojo : esBajo ? colorVerde : colorTexto) : colorGris),
                      _celda(
                        consumo == null ? 'Primera' : esAlto ? '⚠ Alto' : esBajo ? '✓ Bajo' : 'Normal',
                        consumo == null ? colorGris : esAlto ? colorRojo : esBajo ? colorVerde : colorTexto,
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // ── GRÁFICA DE BARRAS ────────────────────────────
          if (consumos.length >= 2) ...[
            pw.Text('GRÁFICA DE CONSUMO MENSUAL', style: pw.TextStyle(fontSize: 9, color: colorGris, letterSpacing: 1.5)),
            pw.SizedBox(height: 8),
            pw.Container(
              height: 140,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: colorCard, borderRadius: pw.BorderRadius.circular(12)),
              child: pw.Chart(
                grid: pw.CartesianGrid(
                  xAxis: pw.FixedAxis.fromStrings(etiquetas, marginStart: 10, marginEnd: 10, ticks: false),
                  yAxis: pw.FixedAxis([0, (consumos.reduce((a, b) => a > b ? a : b) * 1.2).roundToDouble()],
                    divisions: true),
                ),
                datasets: [
                  pw.BarDataSet(
                    color: colorPrimario,
                    width: 12,
                    data: List.generate(consumos.length,
                      (i) => pw.PointChartValue(i.toDouble(), consumos[i])),
                  ),
                  pw.LineDataSet(
                    color: colorVerde,
                    drawPoints: false,
                    data: List.generate(consumos.length,
                      (i) => pw.PointChartValue(i.toDouble(), prom)),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Row(children: [
              pw.Container(width: 12, height: 4, color: colorPrimario),
              pw.SizedBox(width: 5),
              pw.Text('Consumo mensual', style: pw.TextStyle(fontSize: 9, color: colorGris)),
              pw.SizedBox(width: 14),
              pw.Container(width: 12, height: 4, color: colorVerde),
              pw.SizedBox(width: 5),
              pw.Text('Promedio (${prom.toStringAsFixed(1)} ${_serv.unidad})',
                style: pw.TextStyle(fontSize: 9, color: colorGris)),
            ]),
            pw.SizedBox(height: 16),
          ],

          // ── ALERTAS ──────────────────────────────────────
          if (prop.alertaConsumo(_serv) || prop.posibleFugaAgua()) ...[
            pw.Text('ALERTAS ACTIVAS', style: pw.TextStyle(fontSize: 9, color: colorRojo, letterSpacing: 1.5)),
            pw.SizedBox(height: 6),
            if (prop.alertaConsumo(_serv))
              _pdfAlerta('Consumo alto este mes — supera el 20% del promedio', colorRojo, colorCard),
            if (prop.posibleFugaAgua() && _serv == TipoServicio.agua)
              _pdfAlerta('Posible fuga de agua — el consumo mínimo se mantiene elevado', PdfColor.fromHex('#00B4D8'), colorCard),
          ],

          // ── PIE DE PÁGINA ────────────────────────────────
          pw.SizedBox(height: 20),
          pw.Container(height: 0.5, color: PdfColor.fromHex('#1A2B44')),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('AguaLuz HN — Control de Lecturas de Contadores',
                style: pw.TextStyle(fontSize: 8, color: colorGris)),
              pw.Text('Honduras · ${_fechaHoy()}',
                style: pw.TextStyle(fontSize: 8, color: colorGris)),
            ],
          ),
        ],
      ));

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'reporte_${prop.nombre.replaceAll(' ', '_')}_${_serv.name}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error generando PDF: $e'),
          backgroundColor: AppTheme.rojoClaro,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  String _fechaHoy() {
    final now = DateTime.now();
    const meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${now.day} ${meses[now.month - 1]} ${now.year}';
  }

  // ── Helpers de widgets PDF ─────────────────────────────────
  pw.Widget _pdfMetrica(String titulo, String valor, PdfColor color,
      PdfColor bgColor, PdfColor textoColor, PdfColor grisColor) {
    return pw.Expanded(child: pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(color: bgColor, borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(titulo, style: pw.TextStyle(fontSize: 9, color: grisColor)),
        pw.SizedBox(height: 4),
        pw.Text(valor, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
      ]),
    ));
  }

  pw.Widget _celdaHeader(String texto, PdfColor color) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: pw.Text(texto, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: color)),
  );

  pw.Widget _celda(String texto, PdfColor color) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    child: pw.Text(texto, style: pw.TextStyle(fontSize: 9, color: color)),
  );

  pw.Widget _pdfAlerta(String msg, PdfColor color, PdfColor bgColor) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 6),
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(color: bgColor, borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: color, width: 0.5)),
    child: pw.Text(msg, style: pw.TextStyle(fontSize: 10, color: color)),
  );

  // ── UI ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        backgroundColor: AppTheme.fondo,
        elevation: 0,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: AppTheme.rojoClaro.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.rojoClaro, size: 15),
          ),
          const SizedBox(width: 10),
          const Text('Exportar Reporte PDF'),
        ]),
      ),
      body: propiedades.isEmpty
          ? const Center(child: Text('No hay propiedades registradas', style: TextStyle(color: AppTheme.gris)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.fondoAlto,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cian.withValues(alpha: 0.2)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline_rounded, color: AppTheme.cian, size: 18),
                    SizedBox(width: 10),
                    Expanded(child: Text(
                      'El reporte incluye historial completo, gráfica de consumo, factura estimada y alertas activas.',
                      style: TextStyle(fontSize: 12, color: AppTheme.gris, height: 1.4),
                    )),
                  ]),
                ),

                const SizedBox(height: 20),

                // Selector propiedad
                _label('PROPIEDAD'),
                const SizedBox(height: 8),
                DropdownButtonFormField<Propiedad>(
                  value: _propSel,
                  dropdownColor: AppTheme.fondoCard,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.home_rounded, color: AppTheme.cian, size: 18),
                    labelText: 'Seleccionar propiedad',
                  ),
                  items: propiedades.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.nombre, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  )).toList(),
                  onChanged: (p) => setState(() {
                    _propSel = p!;
                    _serv = p.servicios.first;
                  }),
                ),

                const SizedBox(height: 20),

                // Selector servicio
                _label('SERVICIO'),
                const SizedBox(height: 10),
                if (_propSel != null)
                  Row(children: _propSel!.servicios.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _serv = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _serv == s ? s.color.withValues(alpha: 0.12) : Colors.transparent,
                          border: Border.all(color: _serv == s ? s.color : AppTheme.borde, width: _serv == s ? 1.5 : 0.8),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(s.icono, color: _serv == s ? s.color : AppTheme.gris, size: 16),
                          const SizedBox(width: 6),
                          Text(s.nombre, style: TextStyle(fontSize: 13, color: _serv == s ? s.color : AppTheme.gris, fontWeight: _serv == s ? FontWeight.w700 : FontWeight.w400)),
                        ]),
                      ),
                    ),
                  )).toList()),

                const SizedBox(height: 24),

                // Preview del reporte
                if (_propSel != null) ...[
                  _label('CONTENIDO DEL REPORTE'),
                  const SizedBox(height: 10),
                  _ItemPreview(icono: Icons.home_rounded, texto: 'Datos de ${_propSel!.nombre}', color: AppTheme.cian),
                  _ItemPreview(icono: Icons.bar_chart_rounded, texto: 'Historial de ${_propSel!.lecturasPorServicio(_serv).length} lecturas de ${_serv.nombre}', color: AppTheme.verdeClaro),
                  _ItemPreview(icono: Icons.show_chart_rounded, texto: 'Gráfica de consumo mensual', color: AppTheme.agua),
                  _ItemPreview(icono: Icons.receipt_rounded, texto: 'Factura estimada: L. ${_propSel!.facturaEstimada(_serv).toStringAsFixed(0)}', color: AppTheme.luz),
                  if (_propSel!.alertaConsumo(_serv) || _propSel!.posibleFugaAgua())
                    _ItemPreview(icono: Icons.warning_amber_rounded, texto: 'Alertas activas detectadas', color: AppTheme.rojoClaro),
                ],

                const SizedBox(height: 32),

                // Botón generar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generando ? null : _generarYCompartir,
                    icon: _generando
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                    label: Text(_generando ? 'Generando PDF...' : 'Generar y Compartir PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.rojoClaro,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
    );
  }
}

Widget _label(String txt) => Text(txt,
  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.gris, letterSpacing: 1.4));

class _ItemPreview extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;
  const _ItemPreview({required this.icono, required this.texto, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: AppTheme.fondoCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.borde),
    ),
    child: Row(children: [
      Icon(icono, color: color, size: 16),
      const SizedBox(width: 10),
      Expanded(child: Text(texto, style: const TextStyle(fontSize: 13, color: Colors.white70))),
      Icon(Icons.check_circle_rounded, color: color.withValues(alpha: 0.5), size: 14),
    ]),
  );
}