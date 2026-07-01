import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/modelos.dart';

class DatabaseHelper {
  static final DatabaseHelper instancia = DatabaseHelper._();
  static Database? _db;

  DatabaseHelper._();

  Future<Database> get db async {
    _db ??= await _inicializar();
    return _db!;
  }

  Future<Database> _inicializar() async {
    final ruta = join(await getDatabasesPath(), 'agualuz.db');
    return await openDatabase(
      ruta,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE propiedades (
            id TEXT PRIMARY KEY,
            nombre TEXT NOT NULL,
            direccion TEXT NOT NULL,
            colonia TEXT NOT NULL,
            servicios TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE lecturas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            propiedad_id TEXT NOT NULL,
            mes TEXT NOT NULL,
            valor REAL NOT NULL,
            tipo TEXT NOT NULL,
            fecha TEXT NOT NULL,
            foto_path TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migración: agrega foto_path a instalaciones existentes
          await db.execute(
            'ALTER TABLE lecturas ADD COLUMN foto_path TEXT',
          );
        }
      },
    );
  }

  // ── PROPIEDADES ──────────────────────────────────────

  Future<void> insertarPropiedad(Propiedad p) async {
    final base = await db;
    await base.insert('propiedades', {
      'id': p.id,
      'nombre': p.nombre,
      'direccion': p.direccion,
      'colonia': p.colonia,
      'servicios': p.servicios.map((s) => s.name).join(','),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Propiedad>> obtenerPropiedades() async {
    final base = await db;
    final props = await base.query('propiedades');
    final lects = await base.query('lecturas');

    return props.map((row) {
      final id = row['id'] as String;
      final servicios = (row['servicios'] as String)
          .split(',')
          .map((s) => TipoServicio.values.firstWhere((t) => t.name == s))
          .toList();

      final lecturasFiltradas = lects
          .where((l) => l['propiedad_id'] == id)
          .map((l) => Lectura(
                mes: l['mes'] as String,
                valor: l['valor'] as double,
                tipo: TipoServicio.values
                    .firstWhere((t) => t.name == l['tipo']),
                fecha: DateTime.parse(l['fecha'] as String),
                fotoPath: l['foto_path'] as String?,
              ))
          .toList();

      return Propiedad(
        id: id,
        nombre: row['nombre'] as String,
        direccion: row['direccion'] as String,
        colonia: row['colonia'] as String,
        servicios: servicios,
        lecturas: lecturasFiltradas,
      );
    }).toList();
  }

  Future<void> actualizarPropiedad(Propiedad p) async {
    final base = await db;
    await base.update(
      'propiedades',
      {
        'nombre': p.nombre,
        'direccion': p.direccion,
        'colonia': p.colonia,
        'servicios': p.servicios.map((s) => s.name).join(','),
      },
      where: 'id = ?',
      whereArgs: [p.id],
    );
  }

  Future<void> eliminarPropiedad(String id) async {
    final base = await db;
    await base.delete('propiedades', where: 'id = ?', whereArgs: [id]);
    await base.delete('lecturas', where: 'propiedad_id = ?', whereArgs: [id]);
  }

  // ── LECTURAS ─────────────────────────────────────────

  Future<void> insertarLectura(String propiedadId, Lectura l) async {
    final base = await db;
    await base.insert('lecturas', {
      'propiedad_id': propiedadId,
      'mes': l.mes,
      'valor': l.valor,
      'tipo': l.tipo.name,
      'fecha': l.fecha.toIso8601String(),
      'foto_path': l.fotoPath,
    });
  }

  Future<void> eliminarLectura(int id) async {
    final base = await db;
    await base.delete('lecturas', where: 'id = ?', whereArgs: [id]);
  }
}