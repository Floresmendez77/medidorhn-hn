# 💧⚡ MEDIDORHN HN

**Control Inteligente de Servicios Básicos**

Aplicación móvil desarrollada en **Flutter** para Android, orientada a propietarios de bienes inmuebles en Honduras que desean monitorear, registrar y analizar el consumo de agua y electricidad de sus propiedades.

Permite llevar un historial detallado de lecturas de medidores, estimar facturas según tarifas reales de **ENEE** y **SANAA**, generar alertas cuando el consumo supera el promedio histórico, y exportar reportes en PDF, JSON y CSV. Funciona **completamente sin conexión a internet**.

---

## 📋 Tabla de contenidos

- [Objetivos](#-objetivos)
- [Capturas de pantalla](#-capturas-de-pantalla)
- [Funcionalidades](#-funcionalidades)
- [Tecnologías utilizadas](#-tecnologías-utilizadas)
- [Requisitos del sistema](#-requisitos-del-sistema)
- [Instalación y ejecución](#-instalación-y-ejecución)
- [Estructura del proyecto](#-estructura-del-proyecto)
- [Base de datos](#-base-de-datos)
- [Cálculo de tarifas](#-cálculo-de-tarifas)
- [Integrantes](#-integrantes)
- [Licencia](#-licencia)

---

## 🎯 Objetivos

- Registrar lecturas mensuales de medidores de agua y electricidad por propiedad.
- Calcular automáticamente la factura estimada usando tarifas oficiales de ENEE y SANAA.
- Enviar alertas cuando el consumo mensual supera el promedio histórico.
- Visualizar el historial de consumo mediante gráficas comparativas.
- Generar y compartir reportes en PDF, JSON y CSV.
- Funcionar sin conexión a internet con datos almacenados en SQLite local.

## ✨ Funcionalidades

La app está organizada en **9 pantallas** accesibles desde la barra de navegación inferior:

| Pantalla | Función principal |
|---|---|
| 🏠 **Inicio** | Panel principal con resumen de consumo, factura estimada, alertas activas y score de eficiencia. |
| 📝 **Lecturas** | Registrar nuevas lecturas de medidor para cualquier propiedad y servicio. |
| 🧾 **Factura** | Desglose detallado de la factura de luz o agua con cálculo por bloque tarifario. |
| ⚡ **Simulador** | Simular cuánto costaría una factura al agregar o quitar electrodomésticos. |
| 📊 **Historial** | Ver todas las lecturas registradas en orden cronológico con consumo y factura. |
| 🏢 **Propiedades** | Administrar propiedades: agregar, editar, eliminar y ver reportes PDF. |
| 🔔 **Alertas** | Alertas automáticas por consumo alto, posibles fugas o meses sin lectura. |
| 📈 **Gráficos** | Visualizar consumo en gráficas de barras y líneas para los últimos meses. |
| 💾 **Backup** | Exportar datos en JSON o CSV para respaldo o análisis externo. |

### Otras características

- 🌗 **Tema oscuro / claro** con Provider (tema oscuro por defecto).
- 🔔 **Notificaciones** de recordatorio mensual para registrar lecturas.
- 📄 **Reporte PDF** con historial de las últimas 6 lecturas, score de eficiencia y alertas activas.
- 🚨 **Detección de posibles fugas de agua** por patrón de consumo sin variación a la baja durante 3 meses.
- 🔌 **Funciona 100% offline**, todos los datos se guardan localmente en SQLite.

---

## 🛠 Tecnologías utilizadas

- **Flutter** — Framework de UI multiplataforma.
- **Dart** — Lenguaje de programación.
- **sqflite (SQLite)** — Persistencia local de propiedades y lecturas.
- **Provider** — Gestión de estado reactivo (tema oscuro/claro).
- **fl_chart** — Gráficas de barras y líneas de consumo.
- **pdf** — Generación de reportes PDF.
- **share_plus** — Compartir archivos (PDF, JSON, CSV) desde el dispositivo.
- **csv (ListToCsvConverter)** — Exportación de datos a formato CSV.

---

## 💻 Requisitos del sistema

| Requisito | Detalle |
|---|---|
| Sistema operativo | Android 6.0 (API 23) o superior |
| Espacio en disco | Mínimo 50 MB libres |
| Internet | No requerida — funciona completamente offline |
| Permisos | Notificaciones (opcional), Almacenamiento (para exportar) |

---

## 🚀 Instalación y ejecución

### Opción 1 — Instalar el APK

1. Descarga el archivo `MEDIDORHNHN.apk`.
2. Ve a **Ajustes → Seguridad → Fuentes desconocidas** y actívalo.
3. Abre el `.apk` desde el administrador de archivos.
4. Toca **Instalar** y espera.
5. Abre la app; en el primer inicio cargará datos de ejemplo.

### Opción 2 — Ejecutar desde código fuente

```bash
# Clonar el repositorio
git clone https://github.com/Floresmendez77/medidorhn-hn.git
cd medidorhn-hn

# Instalar dependencias
flutter pub get

# Ejecutar en un dispositivo/emulador conectado
flutter run

# Generar el APK de release
flutter build apk --release
```

---

## 📂 Estructura del proyecto

```
lib/
├── main.dart                  # Arranque, Provider y NavigationBar (IndexedStack)
├── database_helper.dart       # Creación y acceso a la base de datos SQLite
├── modelos.dart                # Modelos: Propiedad, Lectura, cálculo de facturas y score
├── theme_provider.dart        # Gestión del tema oscuro/claro
├── app_theme.dart             # Paleta de colores centralizada
├── backup_service.dart        # Exportación a JSON y CSV
├── pantalla_inicio.dart       # Dashboard principal
├── pantalla_factura.dart      # Desglose de factura ENEE/SANAA
├── pantalla_graficos.dart     # Gráficas de consumo (fl_chart)
├── pantalla_reporte_pdf.dart  # Generación de reporte PDF
└── otras_pantallas.dart       # Lecturas, Propiedades, Alertas, Simulador, Historial
```

---

## 🗄 Base de datos

La app usa **sqflite** para persistir datos localmente (sin servidor externo):

```sql
CREATE TABLE propiedades (
  id TEXT PRIMARY KEY,
  nombre TEXT NOT NULL,
  direccion TEXT NOT NULL,
  colonia TEXT NOT NULL,
  servicios TEXT NOT NULL
);

CREATE TABLE lecturas (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  propiedad_id TEXT NOT NULL,
  mes TEXT NOT NULL,
  valor REAL NOT NULL,
  tipo TEXT NOT NULL,
  fecha TEXT NOT NULL,
  foto_path TEXT
);
```

---

## 💡 Cálculo de tarifas

### ⚡ ENEE (electricidad) — por bloques

| Bloque | Rango |
|---|---|
| Social | 0–75 kWh |
| Residencial | 76–150 kWh |
| Medio | 151–300 kWh |
| Alto | 301–500 kWh |
| Premium | 500+ kWh |

Incluye cargo fijo por distribución, ajuste por combustible (DAC 15%) e IVA (15%).

### 🚰 SANAA (agua) — por bloques de m³

| Bloque | Rango |
|---|---|
| 1 | 0–10 m³ |
| 2 | 11–20 m³ |
| 3 | 21–30 m³ |
| 4 | 30+ m³ |

Incluye cargo fijo mensual por conexión.

> ⚠️ Las tarifas son de referencia y pueden variar por ajustes gubernamentales.

---

## ❓ Preguntas frecuentes

**¿Necesito conexión a internet?**
No, MEDIDORHN HN funciona completamente offline.

**¿Qué pasa si desinstalo la app?**
Se pierden todos los datos. Haz un backup en JSON antes de desinstalar.

**¿Puedo registrar varias propiedades?**
Sí, no hay límite. Cada una lleva su propio historial.

**¿La app detecta fugas de agua en tiempo real?**
No, analiza el patrón de lecturas y alerta si detecta consumo continuo sin variación a la baja durante 3 meses consecutivos.

---

## 👥 Integrantes
Andrew Estheven Flores Mendez 32411508

**Docente:** Ing. Alejandro Cruz
**Asignatura:** Programación Móvil — Sección 977
**Sede:** CEUTEC C.A.
**Fecha de entrega:** 17 de junio de 2026

---

## 📄 Licencia

Proyecto académico desarrollado para la asignatura de Programación Móvil, CEUTEC/UNITEC. Uso educativo.
