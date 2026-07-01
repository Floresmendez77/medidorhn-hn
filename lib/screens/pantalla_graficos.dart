import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/modelos.dart';
import '../data/datos.dart';

// ============================================================
// PANTALLA GRÁFICOS — AguaLuz HN  v1.0
// Fase 3: LineChart consumo mensual + BarChart comparativo
// ============================================================

class PantallaGraficos extends StatefulWidget {
  const PantallaGraficos({super.key});
  @override
  State<PantallaGraficos> createState() => _PantallaGraficosState();
}

class _PantallaGraficosState extends State<PantallaGraficos>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Propiedad _prop = propiedades.first;
  TipoServicio _serv = TipoServicio.agua;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Datos calculados ─────────────────────────────────────
  List<double> get _consumos {
    final lects = _prop.lecturasPorServicio(_serv);
    final result = <double>[];
    for (int i = 1; i < lects.length; i++) {
      result.add((lects[i].valor - lects[i - 1].valor).clamp(0, double.infinity));
    }
    return result;
  }

  List<String> get _etiquetas {
    final lects = _prop.lecturasPorServicio(_serv);
    return lects.skip(1).map((l) => l.mes.split(' ').first).toList();
  }

  double get _promedio {
    if (_consumos.isEmpty) return 0;
    return _consumos.reduce((a, b) => a + b) / _consumos.length;
  }

  double get _max => _consumos.isEmpty ? 1 : _consumos.reduce((a, b) => a > b ? a : b);
  double get _min => _consumos.isEmpty ? 0 : _consumos.reduce((a, b) => a < b ? a : b);

  // ── LineChart data ────────────────────────────────────────
  LineChartData _lineData() {
    final spots = _consumos.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final promSpots = _consumos.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), _promedio))
        .toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _max > 0 ? _max / 4 : 1,
        getDrawingHorizontalLine: (_) => FlLine(
          color: AppTheme.borde.withValues(alpha: 0.5),
          strokeWidth: 0.8,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: _max > 0 ? _max / 4 : 1,
            getTitlesWidget: (v, _) => Text(
              v.toStringAsFixed(0),
              style: const TextStyle(fontSize: 9, color: AppTheme.gris),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: _consumos.length > 6 ? (_consumos.length / 6).ceilToDouble() : 1,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= _etiquetas.length) return const SizedBox();
              return Text(
                _etiquetas[i],
                style: const TextStyle(fontSize: 9, color: AppTheme.gris),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppTheme.fondoCard,
          getTooltipItems: (spots) => spots.map((s) {
            final isMain = s.barIndex == 0;
            return LineTooltipItem(
              isMain
                  ? '${s.y.toStringAsFixed(1)} ${_serv.unidad}'
                  : 'Prom: ${s.y.toStringAsFixed(1)}',
              TextStyle(
                color: isMain ? _serv.color : AppTheme.gris,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            );
          }).toList(),
        ),
      ),
      minX: 0,
      maxX: (_consumos.length - 1).toDouble().clamp(1, double.infinity),
      minY: 0,
      maxY: _max * 1.2,
      lineBarsData: [
        // Línea principal de consumo
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: _serv.color,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
              radius: 3.5,
              color: _serv.color,
              strokeWidth: 1.5,
              strokeColor: AppTheme.fondo,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _serv.color.withValues(alpha: 0.25),
                _serv.color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        // Línea de promedio
        LineChartBarData(
          spots: promSpots,
          isCurved: false,
          color: AppTheme.gris.withValues(alpha: 0.6),
          barWidth: 1.2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          dashArray: [6, 4],
        ),
      ],
    );
  }

  // ── BarChart data ─────────────────────────────────────────
  BarChartData _barData() {
    final ultimos = _consumos.length > 6
        ? _consumos.sublist(_consumos.length - 6)
        : _consumos;
    final ultEtiq = _etiquetas.length > 6
        ? _etiquetas.sublist(_etiquetas.length - 6)
        : _etiquetas;

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: _max * 1.25,
      barTouchData: BarTouchData(
        enabled: true,
        touchCallback: (event, response) {
          setState(() {
            _touchedIndex = response?.spot?.touchedBarGroupIndex ?? -1;
          });
        },
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => AppTheme.fondoCard,
          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
            '${ultEtiq[group.x]}\n${rod.toY.toStringAsFixed(1)} ${_serv.unidad}',
            TextStyle(
              color: _serv.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= ultEtiq.length) return const SizedBox();
              return Text(
                ultEtiq[i],
                style: const TextStyle(fontSize: 9, color: AppTheme.gris),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: _max > 0 ? _max / 4 : 1,
            getTitlesWidget: (v, _) => Text(
              v.toStringAsFixed(0),
              style: const TextStyle(fontSize: 9, color: AppTheme.gris),
            ),
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _max > 0 ? _max / 4 : 1,
        getDrawingHorizontalLine: (_) => FlLine(
          color: AppTheme.borde.withValues(alpha: 0.5),
          strokeWidth: 0.8,
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: ultimos.asMap().entries.map((e) {
        final isTouched = e.key == _touchedIndex;
        final esAlto = e.value > _promedio * 1.2;
        final color = esAlto ? AppTheme.rojoClaro : _serv.color;
        return BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
              toY: e.value,
              color: isTouched ? color.withValues(alpha: 1) : color.withValues(alpha: 0.8),
              width: isTouched ? 18 : 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: _max * 1.25,
                color: AppTheme.fondoAlto,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final consumos = _consumos;
    final prom = _promedio;
    final actual = consumos.isNotEmpty ? consumos.last : 0.0;
    final variacion = prom > 0 ? (actual - prom) / prom * 100 : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.fondo,
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.cian.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.show_chart_rounded, color: AppTheme.cian, size: 15),
          ),
          const SizedBox(width: 10),
          const Text('Gráficos'),
        ]),
        backgroundColor: AppTheme.fondo,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButton<Propiedad>(
              value: _prop,
              dropdownColor: AppTheme.fondoCard,
              underline: const SizedBox(),
              style: const TextStyle(color: AppTheme.cian, fontSize: 12),
              items: propiedades.map((p) => DropdownMenuItem(
                value: p,
                child: Text(p.nombre),
              )).toList(),
              onChanged: (p) => setState(() {
                _prop = p!;
                _serv = p.servicios.first;
              }),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.cian,
          unselectedLabelColor: AppTheme.gris,
          indicatorColor: AppTheme.cian,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(icon: Icon(Icons.show_chart_rounded, size: 16), text: 'Tendencia'),
            Tab(icon: Icon(Icons.bar_chart_rounded, size: 16), text: 'Comparativo'),
          ],
        ),
      ),
      body: Column(children: [
        // ── Selector de servicio ──────────────────────────
        Container(
          color: AppTheme.fondo,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: _prop.servicios.map((s) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _serv = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _serv == s ? s.color.withValues(alpha: 0.15) : Colors.transparent,
                  border: Border.all(
                    color: _serv == s ? s.color : AppTheme.borde,
                    width: _serv == s ? 1.5 : 0.8,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(s.nombre, style: TextStyle(
                    fontSize: 12,
                    color: _serv == s ? s.color : AppTheme.gris,
                    fontWeight: _serv == s ? FontWeight.w700 : FontWeight.w400,
                  )),
                ]),
              ),
            ),
          )).toList()),
        ),

        // ── KPI rápidos ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            _KpiChip(label: 'Este mes', valor: '${actual.toStringAsFixed(1)} ${_serv.unidad}', color: _serv.color),
            const SizedBox(width: 8),
            _KpiChip(label: 'Promedio', valor: '${prom.toStringAsFixed(1)} ${_serv.unidad}', color: AppTheme.cian),
            const SizedBox(width: 8),
            _KpiChip(
              label: 'Variación',
              valor: '${variacion > 0 ? '+' : ''}${variacion.toStringAsFixed(1)}%',
              color: variacion > 20 ? AppTheme.rojoClaro : variacion < -10 ? AppTheme.verdeClaro : AppTheme.gris,
            ),
          ]),
        ),

        // ── TabBarView con gráficas ───────────────────────
        Expanded(
          child: consumos.length < 2
              ? _EstadoVacioGrafico(serv: _serv)
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    // Tab 1: LineChart
                    _TabGrafica(
                      titulo: '${_serv.emoji} Consumo mensual (${_serv.unidad})',
                      subtitulo: 'Línea punteada = promedio histórico',
                      child: LineChart(_lineData()),
                      leyenda: [
                        _LeyendaItem(color: _serv.color, label: 'Consumo real'),
                        _LeyendaItem(color: AppTheme.gris, label: 'Promedio', dashed: true),
                      ],
                      stats: _StatsBar(
                        min: _min, max: _max, prom: prom, serv: _serv,
                      ),
                    ),

                    // Tab 2: BarChart
                    _TabGrafica(
                      titulo: '${_serv.emoji} Últimos 6 meses (${_serv.unidad})',
                      subtitulo: 'Rojo = consumo alto · Tocá una barra para detalles',
                      child: BarChart(_barData()),
                      leyenda: [
                        _LeyendaItem(color: _serv.color, label: 'Normal'),
                        _LeyendaItem(color: AppTheme.rojoClaro, label: 'Alto (>20% prom)'),
                      ],
                    ),
                  ],
                ),
        ),
      ]),
    );
  }
}

// ── Widget: Tab con gráfica ───────────────────────────────────
class _TabGrafica extends StatelessWidget {
  final String titulo, subtitulo;
  final Widget child;
  final List<_LeyendaItem> leyenda;
  final Widget? stats;
  const _TabGrafica({
    required this.titulo,
    required this.subtitulo,
    required this.child,
    required this.leyenda,
    this.stats,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (stats != null) ...[stats!, const SizedBox(height: 12)],
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.fondoCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borde),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 2),
          Text(subtitulo, style: const TextStyle(fontSize: 10, color: AppTheme.gris)),
          const SizedBox(height: 16),
          SizedBox(height: 220, child: child),
          const SizedBox(height: 12),
          Row(children: leyenda.map((l) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (l.dashed)
                Row(children: List.generate(3, (_) => Container(
                  width: 4, height: 2,
                  margin: const EdgeInsets.only(right: 1),
                  color: l.color,
                )))
              else
                Container(width: 12, height: 3, decoration: BoxDecoration(color: l.color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 5),
              Text(l.label, style: const TextStyle(fontSize: 10, color: AppTheme.gris)),
            ]),
          )).toList()),
        ]),
      ),
    ]),
  );
}

// ── Widget: Barra de stats ────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final double min, max, prom;
  final TipoServicio serv;
  const _StatsBar({required this.min, required this.max, required this.prom, required this.serv});

  @override
  Widget build(BuildContext context) => Row(children: [
    _StatItem(label: 'Mínimo', valor: '${min.toStringAsFixed(1)} ${serv.unidad}', color: AppTheme.verdeClaro),
    const SizedBox(width: 8),
    _StatItem(label: 'Máximo', valor: '${max.toStringAsFixed(1)} ${serv.unidad}', color: AppTheme.rojoClaro),
    const SizedBox(width: 8),
    _StatItem(label: 'Promedio', valor: '${prom.toStringAsFixed(1)} ${serv.unidad}', color: AppTheme.cian),
  ]);
}

class _StatItem extends StatelessWidget {
  final String label, valor;
  final Color color;
  const _StatItem({required this.label, required this.valor, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.gris, letterSpacing: 0.8)),
        const SizedBox(height: 3),
        Text(valor, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    ),
  );
}

// ── Widget: KPI chip ─────────────────────────────────────────
class _KpiChip extends StatelessWidget {
  final String label, valor;
  final Color color;
  const _KpiChip({required this.label, required this.valor, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.fondoCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borde),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.gris)),
        const SizedBox(height: 2),
        Text(valor, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color), overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

// ── Widget: Leyenda ───────────────────────────────────────────
class _LeyendaItem {
  final Color color;
  final String label;
  final bool dashed;
  const _LeyendaItem({required this.color, required this.label, this.dashed = false});
}

// ── Estado vacío ─────────────────────────────────────────────
class _EstadoVacioGrafico extends StatelessWidget {
  final TipoServicio serv;
  const _EstadoVacioGrafico({required this.serv});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: serv.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.show_chart_rounded, color: serv.color, size: 36),
        ),
        const SizedBox(height: 16),
        const Text('Sin datos suficientes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 8),
        const Text('Necesitás al menos 2 lecturas\npara generar gráficas.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppTheme.gris, height: 1.5)),
      ]),
    ),
  );
}