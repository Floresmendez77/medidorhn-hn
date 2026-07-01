import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'screens/pantalla_inicio.dart';
import 'screens/pantalla_factura.dart';
import 'screens/otras_pantallas.dart';
import 'data/datos.dart';
import 'data/database_helper.dart';
import 'services/notification_service.dart';
import 'screens/pantalla_graficos.dart';
import 'screens/pantalla_backup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar propiedades desde BD
  final dbProps = await DatabaseHelper.instancia.obtenerPropiedades();
  if (dbProps.isEmpty) {
    for (final p in propiedades) {
      await DatabaseHelper.instancia.insertarPropiedad(p);
      for (final l in p.lecturas) {
        await DatabaseHelper.instancia.insertarLectura(p.id, l);
      }
    }
  } else {
    propiedades = dbProps;
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(isDark: true),
      child: const AguaLuzApp(),
    ),
  );

  // Las notificaciones se inicializan DESPUÉS de mostrar la UI y
  // protegidas con try/catch: si el plugin falla (permiso denegado,
  // dispositivo sin soporte, etc.) la app sigue funcionando con normalidad.
  try {
    await NotificationService.instancia.inicializar();
    await NotificationService.instancia.programarRecordatorioMensual();
  } catch (e) {
    debugPrint('No se pudo inicializar/programar notificaciones: $e');
  }
}

class AguaLuzApp extends StatelessWidget {
  const AguaLuzApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'AguaLuz HN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(themeProvider.isDark),
      home: const PantallaPrincipal(),
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});
  @override State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _idx = 0;

  late final List<Widget> _pantallas;

  @override
  void initState() {
    super.initState();
    _pantallas = [
      PantallaInicio(onNavegar: (i) => setState(() => _idx = i)),
      const PantallaLecturas(),
      const PantallaFactura(),
      const PantallaSimulador(),
      const PantallaHistorial(),
      const PantallaPropiedades(),
      const PantallaAlertas(),
      const PantallaGraficos(),
      const PantallaBackup(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _pantallas),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.fondoCard,
          border: Border(top: BorderSide(color: AppTheme.borde, width: 0.8)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _NavItem(Icons.home_rounded, Icons.home_outlined, 'Inicio', 0, _idx, _navegar),
                _NavItem(Icons.edit_note_rounded, Icons.edit_note_outlined, 'Lecturas', 1, _idx, _navegar),
                _NavItem(Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Factura', 2, _idx, _navegar),
                _NavItem(Icons.bolt_rounded, Icons.bolt_outlined, 'Simulador', 3, _idx, _navegar),
                _NavItem(Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Historial', 4, _idx, _navegar),
                _NavItem(Icons.home_work_rounded, Icons.home_work_outlined, 'Propiedades', 5, _idx, _navegar),
                _NavItem(Icons.notifications_active_rounded, Icons.notifications_outlined, 'Alertas', 6, _idx, _navegar),
                _NavItem(Icons.show_chart_rounded, Icons.show_chart_outlined, 'Gráficos', 7, _idx, _navegar),
                _NavItem(Icons.save_alt_rounded, Icons.save_alt_outlined, 'Backup', 8, _idx, _navegar),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navegar(int i) => setState(() => _idx = i);
}

class _NavItem extends StatelessWidget {
  final IconData iconoActivo, iconoInactivo;
  final String label;
  final int indice, actual;
  final Function(int) onTap;

  const _NavItem(this.iconoActivo, this.iconoInactivo, this.label, this.indice, this.actual, this.onTap);

  @override
  Widget build(BuildContext context) {
    final sel = indice == actual;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(indice),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(sel ? iconoActivo : iconoInactivo, key: ValueKey(sel), color: sel ? AppTheme.cian : AppTheme.grisOscuro, size: 22),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(fontSize: 9, color: sel ? AppTheme.cian : AppTheme.grisOscuro, fontWeight: sel ? FontWeight.w700 : FontWeight.w400),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false),
          ),
        ]),
      ),
    );
  }
}