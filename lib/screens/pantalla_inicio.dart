import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/modelos.dart';
import '../data/datos.dart';
import '../widgets/widgets_compartidos.dart';
import '../widgets/theme_toggle.dart';
import 'otras_pantallas.dart';

// ============================================================
// PANTALLA INICIO  v5.0 — Dashboard WOW + TEMA DINÁMICO
// ============================================================

class PantallaInicio extends StatefulWidget {
  final Function(int) onNavegar;
  const PantallaInicio({super.key, required this.onNavegar});
  @override State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p             = propiedades.first;
    final tipHoy        = tips[DateTime.now().day % tips.length];
    final score         = p.scoreEficiencia();
    final posibleFuga   = p.posibleFugaAgua();
    final facturaLuz    = p.servicios.contains(TipoServicio.luz)  ? p.facturaEstimada(TipoServicio.luz)  : 0.0;
    final facturaAgua   = p.servicios.contains(TipoServicio.agua) ? p.facturaEstimada(TipoServicio.agua) : 0.0;
    final totalFacturas = facturaLuz + facturaAgua;
    final consumoLuz    = p.consumoActual(TipoServicio.luz);
    final promLuz       = p.consumoPromedio(TipoServicio.luz);
    final varLuz        = promLuz > 0 ? (consumoLuz - promLuz) / promLuz * 100 : 0.0;
    final alertas       = p.servicios.where((s) => p.alertaConsumo(s)).toList();

    return Scaffold(
      backgroundColor: AppTheme.fondo,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [

              // ── HERO HEADER ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 230,
                pinned: true,
                stretch: true,
                backgroundColor: AppTheme.fondoCard,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                scrolledUnderElevation: 0,
                elevation: 0,
                actions: [
                  ThemeToggle(showLabel: false),
                  const SizedBox(width: 16),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  stretchModes: const [StretchMode.zoomBackground],
                  background: _HeroHeader(
                    score: score,
                    totalFacturas: totalFacturas,
                    varLuz: varLuz,
                    alertCount: alertas.length + (posibleFuga ? 1 : 0),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    // ── ALERTAS ───────────────────────────────────
                    if (alertas.isNotEmpty || posibleFuga) ...[
                      ...alertas.map((s) => _AlertaBanner(
                        icono: Icons.warning_amber_rounded,
                        color: AppTheme.rojoClaro,
                        bgColor: AppTheme.rojoBg,
                        titulo: '⚠ Alerta de ${s.nombre}',
                        subtitulo: 'Consumo ${((p.consumoActual(s)/p.consumoPromedio(s)-1)*100).toStringAsFixed(0)}% sobre tu promedio',
                      )),
                      if (posibleFuga) _AlertaBanner(
                        icono: Icons.water_drop_outlined,
                        color: AppTheme.agua,
                        bgColor: AppTheme.aguaBg,
                        titulo: '💧 Posible fuga de agua',
                        subtitulo: 'Consumo mínimo inusualmente alto. Revisá llaves.',
                      ),
                      const SizedBox(height: 4),
                    ],

                    // ── TARJETAS SERVICIOS ────────────────────────
                    _SeccionLabel(label: 'FACTURA ESTIMADA — DIC 2023'),
                    const SizedBox(height: 10),
                    Row(children: p.servicios.map((s) => Expanded(child: Padding(
                      padding: EdgeInsets.only(right: s != p.servicios.last ? 10 : 0),
                      child: _TarjetaServicio(
                        servicio: s,
                        monto: p.facturaEstimada(s),
                        consumo: p.consumoActual(s),
                        alerta: p.alertaConsumo(s),
                      ),
                    ))).toList()),

                    const SizedBox(height: 24),

                    // ── PREDICCIÓN ────────────────────────────────
                    _SeccionLabel(label: 'PREDICCIÓN — ENE 2024'),
                    const SizedBox(height: 10),
                    _PrediccionCard(prop: p),

                    const SizedBox(height: 24),

                    // ── ACCESOS RÁPIDOS ───────────────────────────
                    _SeccionLabel(label: 'ACCESO RÁPIDO'),
                    const SizedBox(height: 10),
                    _AccesosGrid(onNavegar: widget.onNavegar),

                    const SizedBox(height: 24),

                    // ── PROPIEDAD ACTIVA ──────────────────────────
                    _SeccionLabel(label: 'PROPIEDAD ACTIVA'),
                    const SizedBox(height: 10),
                    _PropiedadCard(prop: p),

                    const SizedBox(height: 24),

                    // ── TIP DEL DÍA ───────────────────────────────
                    _TipCard(tip: tipHoy, onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PantallaTips()),
                    )),

                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── HERO HEADER ────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final int score, alertCount;
  final double totalFacturas, varLuz;
  const _HeroHeader({required this.score, required this.totalFacturas, required this.varLuz, required this.alertCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppTheme.fondoAlto, AppTheme.fondoCard],
          stops: const [0.0, 1.0],
        ),
      ),
      child: Stack(children: [
        // Orbes decorativos
        Positioned(right: -30, top: -30, child: _Orb(size: 180, color: AppTheme.cian, opacity: 0.05)),
        Positioned(left: -20, bottom: 10, child: _Orb(size: 120, color: AppTheme.agua, opacity: 0.04)),
        Positioned(right: 60, bottom: -20, child: _Orb(size: 90, color: AppTheme.luz, opacity: 0.04)),
        // Línea inferior sutil
        Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 1, color: AppTheme.cian.withValues(alpha: 0.08))),
        SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Top row: logo + score
            Row(children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF00B4D8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppTheme.cian.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.speed_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('AguaLuz HN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                Text('Control de Contadores 🇭🇳', style: TextStyle(fontSize: 11, color: AppTheme.cian)),
              ]),
              const Spacer(),
              // Badge alertas
              if (alertCount > 0) Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.rojoClaro.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.rojoClaro.withValues(alpha: 0.4))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.warning_rounded, color: AppTheme.rojoClaro, size: 12),
                  const SizedBox(width: 4),
                  Text('$alertCount', style: const TextStyle(fontSize: 11, color: AppTheme.rojoClaro, fontWeight: FontWeight.w700)),
                ]),
              ),
              ScoreEficiencia(score: score),
            ]),
            const Spacer(),
            // Saludo + total
            const Text('¡Buen día, Juan! 👋', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('L. ${totalFacturas.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -2, height: 1)),
                const Text('estimado diciembre', style: TextStyle(fontSize: 11)),
              ]),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                ChipVariacion(pct: varLuz),
                const SizedBox(height: 4),
                const Text('vs. promedio luz', style: TextStyle(fontSize: 9)),
              ]),
            ]),
          ]),
        )),
      ]),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size, opacity;
  final Color color;
  const _Orb({required this.size, required this.color, required this.opacity});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: opacity)),
  );
}

// ── COMPONENTES ────────────────────────────────────────────────

class _SeccionLabel extends StatelessWidget {
  final String label;
  const _SeccionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(label,
    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.gris, letterSpacing: 1.4));
}

class _AlertaBanner extends StatelessWidget {
  final IconData icono;
  final Color color, bgColor;
  final String titulo, subtitulo;
  const _AlertaBanner({required this.icono, required this.color, required this.bgColor, required this.titulo, required this.subtitulo});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icono, color: color, size: 17)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(subtitulo, style: TextStyle(fontSize: 11, color: AppTheme.textoSecundario)),
      ])),
    ]),
  );
}

class _TarjetaServicio extends StatelessWidget {
  final TipoServicio servicio;
  final double monto, consumo;
  final bool alerta;
  const _TarjetaServicio({required this.servicio, required this.monto, required this.consumo, required this.alerta});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.fondoCard,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: alerta ? AppTheme.rojoClaro.withValues(alpha: 0.4) : servicio.color.withValues(alpha: 0.18)),
      boxShadow: [BoxShadow(color: servicio.color.withValues(alpha: alerta ? 0.0 : 0.04), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: servicio.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(servicio.icono, size: 13, color: servicio.color)),
        const SizedBox(width: 6),
        Text(servicio.nombre, style: TextStyle(fontSize: 11, color: servicio.color, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 10),
      Text('L. ${monto.toStringAsFixed(0)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: alerta ? AppTheme.rojoClaro : AppTheme.blanco, letterSpacing: -0.5, height: 1)),
      const SizedBox(height: 3),
      Text('${consumo.toStringAsFixed(1)} ${servicio.unidad}', style: const TextStyle(fontSize: 10, color: AppTheme.gris)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: servicio.colorBg, borderRadius: BorderRadius.circular(6)),
        child: Text(servicio == TipoServicio.luz ? 'ENEE' : 'SANAA', style: TextStyle(fontSize: 9, color: servicio.color, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      ),
    ]),
  );
}

class _PrediccionCard extends StatelessWidget {
  final Propiedad prop;
  const _PrediccionCard({required this.prop});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppTheme.fondoCard,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.cian.withValues(alpha: 0.15)),
    ),
    child: Column(children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.cian.withValues(alpha: 0.2), AppTheme.cian.withValues(alpha: 0.05)]),
          borderRadius: BorderRadius.circular(10),
        ), child: const Icon(Icons.auto_graph_rounded, color: AppTheme.cian, size: 18)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Predicción inteligente', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          Text('Basada en tu historial de consumo', style: TextStyle(fontSize: 11, color: AppTheme.gris)),
        ])),
      ]),
      const SizedBox(height: 16),
      ...prop.servicios.map((s) {
        final pred     = prop.prediccionConsumo(s);
        final factPred = s == TipoServicio.luz ? calcularFacturaENEE(pred).total : s == TipoServicio.agua ? calcularFacturaSANAA(pred) : pred * 28.5;
        final actual   = prop.facturaEstimada(s);
        final diff     = factPred - actual;
        final sube     = diff > 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: AppTheme.fondo.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(s.icono, size: 15, color: s.color),
            const SizedBox(width: 8),
            Text(s.nombre, style: TextStyle(fontSize: 13, color: s.color, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text('L. ${factPred.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: sube ? AppTheme.rojoBg : AppTheme.verdeBg, borderRadius: BorderRadius.circular(6)),
              child: Text('${sube ? '+' : ''}L.${diff.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 10, color: sube ? AppTheme.rojoClaro : AppTheme.verdeClaro, fontWeight: FontWeight.w700)),
            ),
          ]),
        );
      }),
    ]),
  );
}

class _AccesosGrid extends StatelessWidget {
  final Function(int) onNavegar;
  const _AccesosGrid({required this.onNavegar});

  static const _items = [
    (Icons.edit_note_rounded,    'Lecturas',  AppTheme.cian,       1),
    (Icons.receipt_long_rounded, 'Factura',   AppTheme.luz,        2),
    (Icons.bar_chart_rounded,    'Historial', AppTheme.verdeClaro, 4),
    (Icons.notifications_active_rounded, 'Alertas', AppTheme.rojoClaro, 6),
  ];

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 4, shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.88,
    children: _items.map((item) => _AccesoItem(
      icono: item.$1, label: item.$2, color: item.$3, onTap: () => onNavegar(item.$4),
    )).toList(),
  );
}

class _AccesoItem extends StatelessWidget {
  final IconData icono;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AccesoItem({required this.icono, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icono, color: color, size: 22),
        ),
        const SizedBox(height: 7),
        Text(label, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600, height: 1.2)),
      ]),
    ),
  );
}

class _PropiedadCard extends StatelessWidget {
  final Propiedad prop;
  const _PropiedadCard({required this.prop});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.fondoCard,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.cian.withValues(alpha: 0.12)),
    ),
    child: Row(children: [
      Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.cian.withValues(alpha: 0.2), AppTheme.azul.withValues(alpha: 0.1)]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.home_rounded, color: AppTheme.cian, size: 22),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(prop.nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('${prop.direccion} · ${prop.colonia}', style: const TextStyle(fontSize: 11, color: AppTheme.gris), overflow: TextOverflow.ellipsis),
      ])),
      Row(children: prop.servicios.map((s) => Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: s.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(s.icono, color: s.color, size: 15),
      )).toList()),
    ]),
  );
}

class _TipCard extends StatelessWidget {
  final Tip tip;
  final VoidCallback onTap;
  const _TipCard({required this.tip, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.verdeBg, AppTheme.verdeBg.withValues(alpha: 0.4)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.verdeClaro.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(color: AppTheme.verdeClaro.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(tip.emoji, style: const TextStyle(fontSize: 26))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('CONSEJO DEL DÍA', style: TextStyle(fontSize: 9, color: AppTheme.verdeClaro, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
          const SizedBox(height: 4),
          Text(tip.titulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
          if (tip.ahorroEstimado > 0) ...[
            const SizedBox(height: 4),
            Text('Ahorrá hasta L. ${tip.ahorroEstimado}/mes',
              style: const TextStyle(fontSize: 11, color: AppTheme.verdeClaro, fontWeight: FontWeight.w500)),
          ],
        ])),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppTheme.verdeClaro.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.arrow_forward_rounded, color: AppTheme.verdeClaro, size: 16),
        ),
      ]),
    ),
  );
}