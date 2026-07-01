import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/modelos.dart';

// ============================================================
// WIDGETS COMPARTIDOS  v4.0 — Premium Mobile UI Kit
// ============================================================

class ServicioBadge extends StatelessWidget {
  final TipoServicio tipo; final bool activo; final VoidCallback? onTap;
  const ServicioBadge({super.key, required this.tipo, this.activo = false, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220), curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: activo ? tipo.color.withValues(alpha: 0.18) : Colors.transparent,
        border: Border.all(color: activo ? tipo.color : AppTheme.borde, width: activo ? 1.5 : 0.8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(tipo.icono, size: 14, color: activo ? tipo.color : AppTheme.gris),
        const SizedBox(width: 5),
        Text(tipo.nombre, style: TextStyle(fontSize: 13, color: activo ? tipo.color : AppTheme.gris, fontWeight: activo ? FontWeight.w700 : FontWeight.w400)),
      ]),
    ),
  );
}

class MetricaCard extends StatelessWidget {
  final String titulo, valor, unidad; final IconData icono; final Color color;
  final String? sub; final bool alerta; final VoidCallback? onTap;
  const MetricaCard({super.key, required this.titulo, required this.valor,
    required this.unidad, required this.icono, required this.color,
    this.sub, this.alerta = false, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.fondoCard, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: alerta ? AppTheme.rojoClaro.withValues(alpha: 0.5) : color.withValues(alpha: 0.25), width: alerta ? 1.5 : 0.8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)), child: Icon(icono, color: color, size: 20)),
          const Spacer(),
          if (alerta) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.rojoBg, borderRadius: BorderRadius.circular(8)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.warning_amber_rounded, size: 11, color: AppTheme.rojoClaro),
              SizedBox(width: 3),
              Text('Alto', style: TextStyle(fontSize: 10, color: AppTheme.rojoClaro, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Text(titulo, style: const TextStyle(fontSize: 11, color: AppTheme.gris, letterSpacing: 0.3)),
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(valor, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: alerta ? AppTheme.rojoClaro : color, height: 1.0, letterSpacing: -0.5)),
          const SizedBox(width: 4),
          Padding(padding: const EdgeInsets.only(bottom: 2), child: Text(unidad, style: const TextStyle(fontSize: 12, color: AppTheme.gris))),
        ]),
        if (sub != null) ...[const SizedBox(height: 5), Text(sub!, style: const TextStyle(fontSize: 10, color: AppTheme.grisOscuro, height: 1.3))],
      ]),
    ),
  );
}

class GraficaBarras extends StatelessWidget {
  final List<double> valores; final List<String> etiquetas;
  final Color color; final double? promedioLinea;
  const GraficaBarras({super.key, required this.valores, required this.etiquetas, required this.color, this.promedioLinea});
  @override
  Widget build(BuildContext context) {
    if (valores.isEmpty) return const SizedBox();
    final maxVal = valores.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 135,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(valores.length, (i) {
          final ratio = maxVal > 0 ? valores[i] / maxVal : 0.0;
          final esUltimo = i == valores.length - 1;
          final esAlto = promedioLinea != null && valores[i] > promedioLinea! * 1.2;
          final barColor = esAlto ? AppTheme.rojoClaro : esUltimo ? color : color.withValues(alpha: 0.35);
          return Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
              if (esUltimo) Padding(padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  valores[i].toStringAsFixed(0),
                  style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                )),
              AnimatedContainer(
                duration: Duration(milliseconds: 350 + i * 50), curve: Curves.easeOut,
                height: (100 * ratio).clamp(3.0, 100.0),
                decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(5),
                  boxShadow: esUltimo ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))] : null),
              ),
              const SizedBox(height: 5),
              Text(etiquetas[i], style: TextStyle(fontSize: 9, color: esUltimo ? color : AppTheme.grisOscuro), overflow: TextOverflow.ellipsis),
            ]),
          ));
        }),
      ),
    );
  }
}

// ── Gráfica de Líneas ────────────────────────────────────────
class GraficaLineas extends StatelessWidget {
  final List<double> valores;
  final List<String> etiquetas;
  final Color color;
  final double? promedioLinea;
  const GraficaLineas({super.key, required this.valores, required this.etiquetas, required this.color, this.promedioLinea});

  @override
  Widget build(BuildContext context) {
    if (valores.isEmpty) return const SizedBox();
    final maxVal = valores.reduce((a, b) => a > b ? a : b);
    final minVal = valores.reduce((a, b) => a < b ? a : b);
    final rango = (maxVal - minVal).clamp(1.0, double.infinity);
    final w = MediaQuery.of(context).size.width - 80;
    final h = 100.0;
    final stepX = valores.length > 1 ? w / (valores.length - 1) : w;

    return SizedBox(
      height: h + 30,
      child: Column(children: [
        SizedBox(
          height: h,
          child: CustomPaint(
            size: Size(w, h),
            painter: _LineChartPainter(
              valores: valores,
              color: color,
              promedio: promedioLinea,
              maxVal: maxVal,
              minVal: minVal,
              rango: rango,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Etiquetas eje X
        SizedBox(
          height: 16,
          child: Row(
            children: List.generate(valores.length, (i) => SizedBox(
              width: i == valores.length - 1 ? null : stepX,
              child: Text(
                etiquetas[i],
                style: TextStyle(fontSize: 9, color: i == valores.length - 1 ? color : AppTheme.grisOscuro),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            )),
          ),
        ),
      ]),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> valores;
  final Color color;
  final double? promedio;
  final double maxVal, minVal, rango;

  _LineChartPainter({required this.valores, required this.color, this.promedio,
    required this.maxVal, required this.minVal, required this.rango});

  @override
  void paint(Canvas canvas, Size size) {
    if (valores.length < 2) return;

    final stepX = size.width / (valores.length - 1);

    double toY(double v) => size.height - ((v - minVal) / rango * (size.height * 0.85)) - size.height * 0.05;

    // Línea de promedio
    if (promedio != null) {
      final py = toY(promedio!);
      final promPaint = Paint()
        ..color = AppTheme.gris.withValues(alpha: 0.4)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      const dashW = 6.0, dashGap = 4.0;
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, py), Offset((x + dashW).clamp(0, size.width), py), promPaint);
        x += dashW + dashGap;
      }
    }

    // Área rellena bajo la línea
    final path = Path();
    for (int i = 0; i < valores.length; i++) {
      final x = i * stepX;
      final y = toY(valores[i]);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    final fillPath = Path.from(path)
      ..lineTo((valores.length - 1) * stepX, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill);

    // Línea principal
    canvas.drawPath(path, Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // Puntos
    for (int i = 0; i < valores.length; i++) {
      final x = i * stepX;
      final y = toY(valores[i]);
      final esAlto = promedio != null && valores[i] > promedio! * 1.2;
      final dotColor = esAlto ? AppTheme.rojoClaro : color;
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = dotColor..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => true;
}

class TipCard extends StatelessWidget {
  final Tip tip;
  const TipCard({super.key, required this.tip});
  @override
  Widget build(BuildContext context) {
    final color = tip.tipo?.color ?? AppTheme.cian;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.fondoCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)), child: Center(child: Text(tip.emoji, style: const TextStyle(fontSize: 22)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tip.titulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.blanco)),
          const SizedBox(height: 4),
          Text(tip.descripcion, style: const TextStyle(fontSize: 12, color: AppTheme.gris, height: 1.4)),
          if (tip.ahorroEstimado > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.verdeBg, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.savings_outlined, size: 12, color: AppTheme.verdeClaro),
                const SizedBox(width: 4),
                Text('Ahorrá L. ${tip.ahorroEstimado}/mes', style: const TextStyle(fontSize: 11, color: AppTheme.verdeClaro, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ])),
      ]),
    );
  }
}

class SeccionTitulo extends StatelessWidget {
  final String titulo; final String? accion; final VoidCallback? onAccion;
  const SeccionTitulo({super.key, required this.titulo, this.accion, this.onAccion});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.blanco, letterSpacing: -0.2)),
      const Spacer(),
      if (accion != null) GestureDetector(onTap: onAccion, child: Text(accion!, style: const TextStyle(fontSize: 12, color: AppTheme.cian))),
    ]),
  );
}

// Score circular de eficiencia
class ScoreEficiencia extends StatelessWidget {
  final int score;
  const ScoreEficiencia({super.key, required this.score});
  Color get _color => score >= 80 ? AppTheme.verde : score >= 60 ? AppTheme.amarillo : AppTheme.rojoClaro;
  String get _label => score >= 80 ? 'Excelente' : score >= 60 ? 'Regular' : 'Mejorable';
  @override
  Widget build(BuildContext context) => Column(children: [
    SizedBox(width: 72, height: 72, child: Stack(alignment: Alignment.center, children: [
      CircularProgressIndicator(value: score / 100, strokeWidth: 6, backgroundColor: AppTheme.borde, valueColor: AlwaysStoppedAnimation<Color>(_color)),
      Text('$score', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _color)),
    ])),
    const SizedBox(height: 5),
    Text(_label, style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w600)),
    const Text('eficiencia', style: TextStyle(fontSize: 10, color: AppTheme.gris)),
  ]);
}

// Chip de variación porcentual
class ChipVariacion extends StatelessWidget {
  final double pct;
  const ChipVariacion({super.key, required this.pct});
  @override
  Widget build(BuildContext context) {
    final esAlto = pct > 10; final esBajo = pct < -5;
    final color = esAlto ? AppTheme.rojoClaro : esBajo ? AppTheme.verdeClaro : AppTheme.gris;
    final bg    = esAlto ? AppTheme.rojoBg    : esBajo ? AppTheme.verdeBg    : AppTheme.fondoAlto;
    final icon  = esAlto ? Icons.trending_up_rounded : esBajo ? Icons.trending_down_rounded : Icons.remove_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text('${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// Fila de factura
class FilaFactura extends StatelessWidget {
  final String label; final double monto; final Color color; final bool esTotal;
  const FilaFactura(this.label, this.monto, this.color, {this.esTotal = false, super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: esTotal ? 14 : 13, color: esTotal ? AppTheme.blanco : AppTheme.gris, fontWeight: esTotal ? FontWeight.w700 : FontWeight.w400)),
      const Spacer(),
      Text('L. ${monto.toStringAsFixed(2)}', style: TextStyle(fontSize: esTotal ? 18 : 13, fontWeight: esTotal ? FontWeight.w800 : FontWeight.w500, color: color)),
    ]),
  );
}

// Card contenedor genérico
class AppCard extends StatelessWidget {
  final Widget child; final EdgeInsets? padding; final Color? borderColor;
  const AppCard({super.key, required this.child, this.padding, this.borderColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.fondoCard, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor ?? AppTheme.borde, width: 0.8),
    ),
    child: child,
  );
}