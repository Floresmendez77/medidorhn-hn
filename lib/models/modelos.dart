import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ============================================================
// MODELOS  v4.0 — AguaLuz HN
// Cálculo real ENEE (bloques + DAR 15% + ISV 15%)
// Cálculo SANAA (bloques progresivos)
// Score de eficiencia, predicción de consumo, detección fugas
// ============================================================

enum TipoServicio { agua, luz, gas }

extension TipoServicioX on TipoServicio {
  String get nombre => ['Agua', 'Luz', 'Gas'][index];
  String get unidad => ['m³', 'kWh', 'kg'][index];
  String get emoji  => ['💧', '⚡', '🔥'][index];
  Color get color {
    switch (this) {
      case TipoServicio.agua: return AppTheme.agua;
      case TipoServicio.luz:  return AppTheme.luz;
      case TipoServicio.gas:  return AppTheme.gas;
    }
  }
  Color get colorBg {
    switch (this) {
      case TipoServicio.agua: return AppTheme.aguaBg;
      case TipoServicio.luz:  return AppTheme.luzBg;
      case TipoServicio.gas:  return AppTheme.gasBg;
    }
  }
  IconData get icono {
    switch (this) {
      case TipoServicio.agua: return Icons.water_drop_outlined;
      case TipoServicio.luz:  return Icons.electric_bolt;
      case TipoServicio.gas:  return Icons.local_fire_department;
    }
  }
}

// ── Lectura mensual ──────────────────────────────────────────
class Lectura {
  final String mes;
  final double valor;
  final TipoServicio tipo;
  final DateTime fecha;
  final String? fotoPath; // ruta local de la foto del medidor
  const Lectura({
    required this.mes,
    required this.valor,
    required this.tipo,
    required this.fecha,
    this.fotoPath,
  });
}

// ── Resultado ENEE ───────────────────────────────────────────
class ResultadoFactura {
  final double consumoKwh;
  final double energiaBase;
  final double cargoFijo;
  final double dar;
  final double impVentas;
  final double total;
  final String bloque;
  const ResultadoFactura({
    required this.consumoKwh, required this.energiaBase, required this.cargoFijo,
    required this.dar, required this.impVentas, required this.total, required this.bloque,
  });
}

// ── CÁLCULO ENEE 2024 ────────────────────────────────────────
ResultadoFactura calcularFacturaENEE(double kwh) {
  double energia = 0; String bloque = '';
  if (kwh <= 75)       { energia = kwh * 1.4946; bloque = 'Bloque Social (0–75 kWh)'; }
  else if (kwh <= 150) { energia = 75*1.4946 + (kwh-75)*2.0990; bloque = 'Bloque Residencial (76–150 kWh)'; }
  else if (kwh <= 300) { energia = 75*1.4946 + 75*2.0990 + (kwh-150)*3.6049; bloque = 'Bloque Medio (151–300 kWh)'; }
  else if (kwh <= 500) { energia = 75*1.4946 + 75*2.0990 + 150*3.6049 + (kwh-300)*4.8012; bloque = 'Bloque Alto (301–500 kWh)'; }
  else                 { energia = 75*1.4946 + 75*2.0990 + 150*3.6049 + 200*4.8012 + (kwh-500)*6.1527; bloque = 'Bloque Premium (500+ kWh)'; }
  const cargoFijo = 30.0;
  final subtotal = energia + cargoFijo;
  final dar = subtotal * 0.15;
  final baseIsv = subtotal + dar;
  final impVentas = baseIsv * 0.15;
  return ResultadoFactura(consumoKwh: kwh, energiaBase: energia, cargoFijo: cargoFijo, dar: dar, impVentas: impVentas, total: baseIsv + impVentas, bloque: bloque);
}

// ── CÁLCULO SANAA ────────────────────────────────────────────
double calcularFacturaSANAA(double m3) {
  if (m3 <= 10) return 15.0;
  if (m3 <= 20) return 15.0 + (m3 - 10) * 8.5;
  if (m3 <= 30) return 15.0 + 85.0 + (m3 - 20) * 13.0;
  return 15.0 + 85.0 + 130.0 + (m3 - 30) * 18.0;
}

// ── Propiedad ────────────────────────────────────────────────
class Propiedad {
  final String id, nombre, direccion, colonia;
  final List<TipoServicio> servicios;
  final List<Lectura> lecturas;
  const Propiedad({required this.id, required this.nombre, required this.direccion,
    required this.colonia, required this.servicios, required this.lecturas});

  List<Lectura> lecturasPorServicio(TipoServicio t) =>
    lecturas.where((l) => l.tipo == t).toList()..sort((a, b) => a.fecha.compareTo(b.fecha));

  double consumoActual(TipoServicio t) {
    final l = lecturasPorServicio(t);
    if (l.length < 2) return 0;
    return (l.last.valor - l[l.length - 2].valor).clamp(0, double.infinity);
  }

  double consumoPromedio(TipoServicio t) {
    final l = lecturasPorServicio(t);
    if (l.length < 2) return 0;
    double s = 0; for (int i = 1; i < l.length; i++) s += l[i].valor - l[i-1].valor;
    return s / (l.length - 1);
  }

  bool alertaConsumo(TipoServicio t) {
    final a = consumoActual(t), p = consumoPromedio(t);
    return p > 0 && a > p * 1.20;
  }

  // Predicción próximo mes (media ponderada — más peso a meses recientes)
  double prediccionConsumo(TipoServicio t) {
    final l = lecturasPorServicio(t);
    if (l.length < 2) return consumoPromedio(t);
    final consumos = <double>[];
    for (int i = 1; i < l.length; i++) consumos.add(l[i].valor - l[i-1].valor);
    double suma = 0, pesoTotal = 0;
    for (int i = 0; i < consumos.length; i++) {
      final peso = (i + 1).toDouble();
      suma += consumos[i] * peso; pesoTotal += peso;
    }
    return suma / pesoTotal;
  }

  // Score 0–100 de eficiencia energética
  int scoreEficiencia() {
    int score = 80;
    for (final s in servicios) {
      final a = consumoActual(s), p = consumoPromedio(s);
      if (p == 0) continue;
      final r = a / p;
      if (r > 1.3) score -= 22;
      else if (r > 1.1) score -= 10;
      else if (r < 0.85) score += 8;
    }
    return score.clamp(0, 100);
  }

  // Detección de posible fuga de agua
  // Si el consumo mínimo de los últimos 3 meses es mayor al 80% del promedio
  bool posibleFugaAgua() {
    final l = lecturasPorServicio(TipoServicio.agua);
    if (l.length < 4) return false;
    final consumos = <double>[];
    for (int i = 1; i < l.length; i++) consumos.add(l[i].valor - l[i-1].valor);
    final ultimos = consumos.length >= 3 ? consumos.sublist(consumos.length - 3) : consumos;
    final minConsume = ultimos.reduce((a, b) => a < b ? a : b);
    final prom = consumoPromedio(TipoServicio.agua);
    // Fuga probable si el mes "más bajo" sigue siendo 80%+ del promedio (nunca baja)
    return prom > 0 && minConsume >= prom * 0.80 && consumos.length >= 4;
  }

  // Factura estimada del mes
  double facturaEstimada(TipoServicio t) {
    final c = consumoActual(t);
    if (t == TipoServicio.luz) return calcularFacturaENEE(c).total;
    if (t == TipoServicio.agua) return calcularFacturaSANAA(c);
    return c * 28.5; // Gas: L. 28.5/kg aprox.
  }

  // Factura predicha próximo mes
  double facturaPredicha(TipoServicio t) {
    final c = prediccionConsumo(t);
    if (t == TipoServicio.luz) return calcularFacturaENEE(c).total;
    if (t == TipoServicio.agua) return calcularFacturaSANAA(c);
    return c * 28.5;
  }
}

// ── Electrodoméstico para simulador ─────────────────────────
class Electrodomestico {
  final String nombre, emoji;
  final double wattsPromedio;
  const Electrodomestico({required this.nombre, required this.emoji, required this.wattsPromedio});

  double kwhMes(double horasDia, int diasMes) => wattsPromedio * horasDia * diasMes / 1000;
  double costoMes(double horasDia, int diasMes) => calcularFacturaENEE(kwhMes(horasDia, diasMes)).total;
}

const List<Electrodomestico> electrodomesticos = [
  Electrodomestico(nombre: 'Aire Acondicionado', emoji: '❄️', wattsPromedio: 1500),
  Electrodomestico(nombre: 'Refrigeradora',      emoji: '🧊', wattsPromedio: 150),
  Electrodomestico(nombre: 'Televisor 55"',       emoji: '📺', wattsPromedio: 120),
  Electrodomestico(nombre: 'Lavadora',           emoji: '🫧', wattsPromedio: 500),
  Electrodomestico(nombre: 'Ducha Eléctrica',    emoji: '🚿', wattsPromedio: 3500),
  Electrodomestico(nombre: 'Microondas',         emoji: '📡', wattsPromedio: 1100),
  Electrodomestico(nombre: 'Bombillo LED',       emoji: '💡', wattsPromedio: 10),
  Electrodomestico(nombre: 'Computadora',        emoji: '💻', wattsPromedio: 200),
  Electrodomestico(nombre: 'Plancha',            emoji: '👔', wattsPromedio: 1200),
  Electrodomestico(nombre: 'Ventilador',         emoji: '🌀', wattsPromedio: 60),
];

// ── Tip ──────────────────────────────────────────────────────
class Tip {
  final String titulo, descripcion, emoji;
  final TipoServicio? tipo;
  final int ahorroEstimado;
  const Tip({required this.titulo, required this.descripcion, required this.emoji, this.tipo, required this.ahorroEstimado});
}