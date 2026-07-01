import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ════════════════════════════════════════════════════════
  // COLORES OSCUROS (TEMA BASE)
  // ════════════════════════════════════════════════════════
  
  static const Color fondoOscuro        = Color(0xFF070B16);
  static const Color fondoCardOscuro    = Color(0xFF0D1526);
  static const Color fondoAltoOscuro    = Color(0xFF121E32);
  static const Color bordeOscuro        = Color(0xFF1A2B44);
  static const Color agua         = Color(0xFF00B4D8);
  static const Color aguaBgOscuro = Color(0xFF042030);
  static const Color luz          = Color(0xFFFFD60A);
  static const Color luzBgOscuro  = Color(0xFF1E1800);
  static const Color gas          = Color(0xFFFF6B35);
  static const Color gasBgOscuro  = Color(0xFF200E00);
  static const Color cian         = Color(0xFF00E5FF);
  static const Color cianOscuro   = Color(0xFF00B4D8);
  static const Color azul         = Color(0xFF1E88E5);
  static const Color grisClaro    = Color(0xFF7A90A8);
  static const Color grisOscuro   = Color(0xFF3A5068);
  static const Color verde        = Color(0xFF00E676);
  static const Color verdeBgOscuro= Color(0xFF002A14);
  static const Color verdeExito   = Color(0xFF00C853);
  static const Color verdeClaro   = Color(0xFF69F0AE);
  static const Color amarillo     = Color(0xFFFFD60A);
  static const Color naranja      = Color(0xFFFF9800);
  static const Color rojo         = Color(0xFFD50000);
  static const Color rojoClaro    = Color(0xFFFF5252);
  static const Color rojoBgOscuro = Color(0xFF1E0808);
  static const Color blanco       = Color(0xFFF0F6FF);
  static const Color gris         = Color(0xFF7A90A8);

  // ════════════════════════════════════════════════════════
  // COLORES CLAROS
  // ════════════════════════════════════════════════════════
  
  static const Color fondoClaro        = Color(0xFFFAFBFC);
  static const Color fondoCardClaro    = Color(0xFFFFFFFF);
  static const Color fondoAltoClaro    = Color(0xFFF5F7FA);
  static const Color bordeClaro        = Color(0xFFE8EEF5);
  static const Color aguaBgClaro = Color(0xFFE0F7FF);
  static const Color luzBgClaro  = Color(0xFFFFF9E0);
  static const Color gasBgClaro  = Color(0xFFFFE8DC);
  static const Color verdeBgClaro= Color(0xFFE0F5ED);
  static const Color rojoBgClaro = Color(0xFFFFE8E8);
  static const Color negro       = Color(0xFF1A1A1A);
  static const Color grisOscuroClaro = Color(0xFF5A6B7A);

  // ════════════════════════════════════════════════════════
  // TEMA DINÁMICO (cambia según modo)
  // ════════════════════════════════════════════════════════

  static late Color fondo;
  static late Color fondoCard;
  static late Color fondoAlto;
  static late Color borde;
  static late Color aguaBg;
  static late Color luzBg;
  static late Color gasBg;
  static late Color verdeBg;
  static late Color rojoBg;
  static late Color textoSecundario;
  static late Color textoTerciario;

  static void setTeemDark(bool isDark) {
    if (isDark) {
      fondo = fondoOscuro;
      fondoCard = fondoCardOscuro;
      fondoAlto = fondoAltoOscuro;
      borde = bordeOscuro;
      aguaBg = aguaBgOscuro;
      luzBg = luzBgOscuro;
      gasBg = gasBgOscuro;
      verdeBg = verdeBgOscuro;
      rojoBg = rojoBgOscuro;
      textoSecundario = grisClaro;
      textoTerciario = grisOscuro;
    } else {
      fondo = fondoClaro;
      fondoCard = fondoCardClaro;
      fondoAlto = fondoAltoClaro;
      borde = bordeClaro;
      aguaBg = aguaBgClaro;
      luzBg = luzBgClaro;
      gasBg = gasBgClaro;
      verdeBg = verdeBgClaro;
      rojoBg = rojoBgClaro;
      textoSecundario = grisOscuroClaro;
      textoTerciario = Color(0xFF7A8BA5);
    }
  }

  static ThemeData buildTheme(bool isDark) {
    setTeemDark(isDark);
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: fondo,
      fontFamily: 'Roboto',
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: cian, secondary: azul, surface: fondoCardOscuro, error: rojoClaro,
            )
          : ColorScheme.light(
              primary: cian, secondary: azul, surface: fondoCardClaro, error: rojo,
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? blanco : negro,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: isDark ? blanco : negro,
        ),
      ),
      cardTheme: CardThemeData(
        color: fondoCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borde, width: 0.8),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: fondoCard,
        selectedItemColor: cian,
        unselectedItemColor: isDark ? grisOscuro : Color(0xFFA0A0A0),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fondoAlto,
        hintStyle: TextStyle(
          color: isDark ? grisOscuro : Color(0xFFA0A0A0),
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borde, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borde, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cian, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cian,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isDark ? fondoAltoOscuro : Color(0xFF333333),
        contentTextStyle: TextStyle(color: isDark ? blanco : Color(0xFFFFFAFA)),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: isDark ? blanco : negro),
        bodyMedium: TextStyle(color: isDark ? grisClaro : grisOscuroClaro),
        bodySmall: TextStyle(color: isDark ? grisOscuro : Color(0xFFA0A0A0)),
        labelLarge: TextStyle(color: isDark ? blanco : negro, fontWeight: FontWeight.w700),
      ),
    );
  }

  static ThemeData get tema => buildTheme(true);
  static ThemeData get temaClaro => buildTheme(false);
}