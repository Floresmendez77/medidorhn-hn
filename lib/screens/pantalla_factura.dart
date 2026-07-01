import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/modelos.dart';
import '../data/datos.dart';
import '../widgets/widgets_compartidos.dart';

// ============================================================
// PANTALLA FACTURA  v5.0 — Calculadora ENEE Premium
// ============================================================

class PantallaFactura extends StatefulWidget {
  const PantallaFactura({super.key});
  @override State<PantallaFactura> createState() => _PantallaFacturaState();
}

class _PantallaFacturaState extends State<PantallaFactura> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  ResultadoFactura? _res;
  bool _calculado = false;
  late AnimationController _anim;
  late Animation<double> _fade;
  Propiedad _prop = propiedades.first;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    final consumo = _prop.consumoActual(TipoServicio.luz);
    if (consumo > 0) { _ctrl.text = consumo.toStringAsFixed(0); _calcular(); }
  }

  @override void dispose() { _ctrl.dispose(); _anim.dispose(); super.dispose(); }

  void _calcular() {
    final val = double.tryParse(_ctrl.text.trim());
    if (val == null || val <= 0) return;
    setState(() { _res = calcularFacturaENEE(val); _calculado = true; });
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final promHN       = benchmarkHogares['luz_promedio_hn']!;
    final eficHN       = benchmarkHogares['luz_eficiente']!;
    final consumoActual = _prop.consumoActual(TipoServicio.luz);

    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        backgroundColor: AppTheme.fondo,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF8F00), AppTheme.luz], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: AppTheme.luz.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.electric_bolt, color: Colors.black, size: 15),
          ),
          const SizedBox(width: 10),
          const Text('Calculadora ENEE'),
        ]),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 12), child: DropdownButton<Propiedad>(
            value: _prop, dropdownColor: AppTheme.fondoCard, underline: const SizedBox(),
            style: const TextStyle(color: AppTheme.cian, fontSize: 12),
            items: propiedades.map((p) => DropdownMenuItem(value: p, child: Text(p.nombre))).toList(),
            onChanged: (p) { setState(() {
              _prop = p!;
              final c = _prop.consumoActual(TipoServicio.luz);
              if (c > 0) { _ctrl.text = c.toStringAsFixed(0); _calcular(); }
              else { _ctrl.clear(); _res = null; _calculado = false; }
            }); },
          )),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── INGRESO ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.fondoCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.luz.withValues(alpha: 0.25)),
              boxShadow: [BoxShadow(color: AppTheme.luz.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.speed_rounded, color: AppTheme.luz, size: 14),
                const SizedBox(width: 6),
                const Text('Consumo mensual', style: TextStyle(fontSize: 11, color: AppTheme.gris, letterSpacing: 0.5)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextField(
                  controller: _ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.luz, letterSpacing: -1),
                  decoration: InputDecoration(
                    hintText: '185',
                    hintStyle: TextStyle(color: AppTheme.luz.withValues(alpha: 0.2), fontSize: 32, fontWeight: FontWeight.w800),
                    suffixText: 'kWh',
                    suffixStyle: const TextStyle(color: AppTheme.gris, fontSize: 14, fontWeight: FontWeight.w400),
                    fillColor: Colors.transparent,
                  ),
                )),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _calcular,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.luz, Color(0xFFFF8F00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppTheme.luz.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5))],
                    ),
                    child: const Icon(Icons.calculate_rounded, color: Colors.black, size: 26),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              // Chips de consumo rápido
              Wrap(spacing: 8, runSpacing: 6, children: [75, 150, 185, 300, 500].map((v) => GestureDetector(
                onTap: () { _ctrl.text = '$v'; _calcular(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.luz.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.luz.withValues(alpha: 0.2)),
                  ),
                  child: Text('$v kWh', style: const TextStyle(fontSize: 11, color: AppTheme.luz, fontWeight: FontWeight.w500)),
                ),
              )).toList()),
            ]),
          ),

          const SizedBox(height: 20),

          // ── COMPARACIÓN HONDURAS ─────────────────────
          if (consumoActual > 0) ...[
            _Label('TU HOGAR VS HONDURAS'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.fondoCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borde),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _BarraComparacion('Tu consumo', consumoActual, consumoActual > promHN ? AppTheme.rojoClaro : AppTheme.cian, '${consumoActual.toStringAsFixed(0)} kWh'),
                const SizedBox(height: 12),
                _BarraComparacion('Promedio HN', promHN, AppTheme.naranja, '${promHN.toStringAsFixed(0)} kWh'),
                const SizedBox(height: 12),
                _BarraComparacion('Eficiente HN', eficHN, AppTheme.verdeClaro, '${eficHN.toStringAsFixed(0)} kWh'),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: consumoActual <= eficHN ? AppTheme.verdeBg : consumoActual <= promHN ? AppTheme.luzBg : AppTheme.rojoBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    consumoActual <= eficHN ? '🏆 ¡Sos un hogar eficiente! Bajo el promedio hondureño.'
                    : consumoActual <= promHN ? '👍 Consumo normal para Honduras. Aún podés mejorar.'
                    : '⚠ Consumo alto. El promedio en Honduras es ${promHN.toStringAsFixed(0)} kWh/mes.',
                    style: TextStyle(fontSize: 12, color: consumoActual <= eficHN ? AppTheme.verdeClaro : consumoActual <= promHN ? AppTheme.amarillo : AppTheme.rojoClaro, height: 1.4),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // ── RESULTADO ────────────────────────────────
          if (_calculado && _res != null) FadeTransition(
            opacity: _fade,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Total
              Container(
                width: double.infinity, padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF0F1F00), Color(0xFF070B16)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.verdeClaro.withValues(alpha: 0.3)),
                  boxShadow: [BoxShadow(color: AppTheme.verdeClaro.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(children: [
                  const Text('TOTAL A PAGAR', style: TextStyle(fontSize: 10, color: AppTheme.verdeClaro, letterSpacing: 2, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text('L. ${_res!.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -2, height: 1)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(color: AppTheme.luz.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.luz.withValues(alpha: 0.2))),
                    child: Text(_res!.bloque, style: const TextStyle(fontSize: 11, color: AppTheme.luz, fontWeight: FontWeight.w500)),
                  ),
                ]),
              ),

              const SizedBox(height: 20),
              _Label('DESGLOSE PASO A PASO'),
              const SizedBox(height: 6),
              const Text('Así lo calcula la ENEE, bloque por bloque', style: TextStyle(fontSize: 11, color: AppTheme.gris)),
              const SizedBox(height: 14),

              _PasoFactura('01', 'Energía (bloques progresivos)', 'Más consumís → más pagás por kWh', 'L. ${_res!.energiaBase.toStringAsFixed(2)}', AppTheme.luz, _res!.bloque, true, _res!.consumoKwh),
              const SizedBox(height: 10),
              _PasoFactura('02', 'Cargo fijo ENEE', 'Se cobra sin importar el consumo', 'L. ${_res!.cargoFijo.toStringAsFixed(2)}', AppTheme.cian, 'L. 30.00 fijos mensuales'),
              const SizedBox(height: 10),
              _PasoFactura('03', 'DAR — Alumbrado Público', '15% sobre (energía + cargo fijo)', 'L. ${_res!.dar.toStringAsFixed(2)}', AppTheme.naranja, 'L. ${(_res!.energiaBase + _res!.cargoFijo).toStringAsFixed(2)} × 15%'),
              const SizedBox(height: 10),
              _PasoFactura('04', 'ISV — Impuesto sobre Ventas', '15% sobre el subtotal + DAR', 'L. ${_res!.impVentas.toStringAsFixed(2)}', AppTheme.rojoClaro, 'L. ${(_res!.energiaBase + _res!.cargoFijo + _res!.dar).toStringAsFixed(2)} × 15%'),
              const SizedBox(height: 16),

              // Resumen tabla
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.fondoCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.borde)),
                child: Column(children: [
                  FilaFactura('Energía (${_res!.consumoKwh.toStringAsFixed(0)} kWh)', _res!.energiaBase, AppTheme.luz),
                  const SizedBox(height: 4),
                  FilaFactura('Cargo fijo', _res!.cargoFijo, AppTheme.cian),
                  const SizedBox(height: 4),
                  FilaFactura('DAR 15%', _res!.dar, AppTheme.naranja),
                  const SizedBox(height: 4),
                  FilaFactura('ISV 15%', _res!.impVentas, AppTheme.rojoClaro),
                  const SizedBox(height: 8),
                  Divider(color: AppTheme.borde, height: 1),
                  const SizedBox(height: 10),
                  FilaFactura('TOTAL', _res!.total, AppTheme.verdeClaro, esTotal: true),
                ]),
              ),

              const SizedBox(height: 16),

              // Tarifas referencia
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.fondoCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.borde)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.table_rows_rounded, color: AppTheme.gris, size: 14),
                    SizedBox(width: 6),
                    Text('Tarifas ENEE vigentes por bloque', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                  ]),
                  const SizedBox(height: 12),
                  ...[
                    ['0–75 kWh',    'L. 1.4946/kWh', 'Social'],
                    ['76–150 kWh',  'L. 2.0990/kWh', 'Residencial'],
                    ['151–300 kWh', 'L. 3.6049/kWh', 'Medio'],
                    ['301–500 kWh', 'L. 4.8012/kWh', 'Alto'],
                    ['500+ kWh',    'L. 6.1527/kWh', 'Premium'],
                  ].map((r) {
                    final esActual = _res!.bloque.contains(r[2]);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: esActual ? AppTheme.luz.withValues(alpha: 0.07) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: esActual ? Border.all(color: AppTheme.luz.withValues(alpha: 0.25)) : null,
                      ),
                      child: Row(children: [
                        if (esActual) const Icon(Icons.arrow_right_rounded, color: AppTheme.luz, size: 16),
                        if (!esActual) const SizedBox(width: 16),
                        Text(r[0], style: TextStyle(fontSize: 12, color: esActual ? AppTheme.luz : AppTheme.gris)),
                        const Spacer(),
                        Text(r[1], style: TextStyle(fontSize: 12, fontWeight: esActual ? FontWeight.w700 : FontWeight.normal, color: esActual ? AppTheme.luz : Colors.white60)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: (esActual ? AppTheme.luz : AppTheme.gris).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(r[2], style: TextStyle(fontSize: 9, color: esActual ? AppTheme.luz : AppTheme.grisOscuro, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    );
                  }),
                ]),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String label;
  const _Label(this.label);
  @override
  Widget build(BuildContext context) => Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.gris, letterSpacing: 1.4));
}

class _BarraComparacion extends StatelessWidget {
  final String label; final double valor; final Color color; final String texto;
  const _BarraComparacion(this.label, this.valor, this.color, this.texto);
  @override
  Widget build(BuildContext context) {
    const maxVal = 600.0;
    return Row(children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.gris))),
      Expanded(child: Stack(children: [
        Container(height: 6, decoration: BoxDecoration(color: AppTheme.borde, borderRadius: BorderRadius.circular(3))),
        FractionallySizedBox(
          widthFactor: (valor / maxVal).clamp(0.0, 1.0),
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withValues(alpha: 0.6), color]),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ])),
      const SizedBox(width: 10),
      Text(texto, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _PasoFactura extends StatefulWidget {
  final String numero, titulo, subtitulo, valor, detalle;
  final Color color; final bool expandido; final double? kwh;
  const _PasoFactura(this.numero, this.titulo, this.subtitulo, this.valor, this.color, this.detalle, [this.expandido = false, this.kwh]);
  @override State<_PasoFactura> createState() => _PasoFacturaState();
}
class _PasoFacturaState extends State<_PasoFactura> {
  late bool _open;
  @override void initState() { super.initState(); _open = widget.expandido; }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _open = !_open),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _open ? widget.color.withValues(alpha: 0.3) : widget.color.withValues(alpha: 0.12)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [widget.color.withValues(alpha: 0.2), widget.color.withValues(alpha: 0.05)]),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(widget.numero, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: widget.color))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.titulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            Text(widget.subtitulo, style: const TextStyle(fontSize: 10, color: AppTheme.gris)),
          ])),
          Text(widget.valor, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: widget.color)),
          const SizedBox(width: 4),
          Icon(_open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppTheme.gris, size: 18),
        ]),
        if (_open) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: widget.color.withValues(alpha: 0.1))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.detalle, style: TextStyle(fontSize: 11, color: widget.color, fontWeight: FontWeight.w500)),
              if (widget.kwh != null) ...[const SizedBox(height: 10), _DesgloseBloques(consumo: widget.kwh!)],
            ]),
          ),
        ],
      ]),
    ),
  );
}

class _DesgloseBloques extends StatelessWidget {
  final double consumo;
  const _DesgloseBloques({required this.consumo});
  @override
  Widget build(BuildContext context) {
    final bloques = <Map<String, dynamic>>[];
    double r = consumo;
    void agrega(String rango, double max, double tarifa) {
      final en = r.clamp(0, max).toDouble();
      if (en > 0) { bloques.add({'rango': rango, 'kwh': en, 'tarifa': tarifa, 'sub': en * tarifa}); r -= en; }
    }
    agrega('0–75 kWh',    75,  1.4946);
    agrega('76–150 kWh',  75,  2.0990);
    agrega('151–300 kWh', 150, 3.6049);
    agrega('301–500 kWh', 200, 4.8012);
    if (r > 0) bloques.add({'rango': '500+ kWh', 'kwh': r, 'tarifa': 6.1527, 'sub': r * 6.1527});
    return Column(children: bloques.map((b) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: AppTheme.luz.withValues(alpha: 0.5), shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('${(b['kwh'] as double).toStringAsFixed(0)} kWh × L. ${b['tarifa']}', style: const TextStyle(fontSize: 11, color: Colors.white60)),
        const Spacer(),
        Text('L. ${(b['sub'] as double).toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppTheme.luz, fontWeight: FontWeight.w600)),
      ]),
    )).toList());
  }
}