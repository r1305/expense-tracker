import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatasource {
  static Database? _db;

  Future<Database> get db async => _db ??= await _init();

  Future<Database> _init() async {
    if (kIsWeb) {
      // Configurar el factory para web
      databaseFactory = databaseFactoryFfiWeb;
    }

    final path = kIsWeb ? 'expenses.db' : join(await getDatabasesPath(), 'expenses.db');
    
    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await _createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS categories(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL
              )
            ''');
            await db.execute(
                'ALTER TABLE expenses ADD COLUMN category_id INTEGER REFERENCES categories(id)');
          }
        },
      ),
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        date TEXT NOT NULL,
        category_id INTEGER REFERENCES categories(id)
      )
    ''');
    
    await db.execute('''
      CREATE TABLE salary(
        id INTEGER PRIMARY KEY,
        amount REAL NOT NULL,
        currency TEXT NOT NULL
      )
    ''');

    // Insertar categorías por defecto
    await db.execute("INSERT INTO categories (name) VALUES ('Comida')");
    await db.execute("INSERT INTO categories (name) VALUES ('Transporte')");
    await db.execute("INSERT INTO categories (name) VALUES ('Entretenimiento')");
    await db.execute("INSERT INTO categories (name) VALUES ('Otros')");
  }

  Future<List<Map<String, dynamic>>> query(String table,
      {String? orderBy, String? where, List<Object?>? whereArgs}) async {
    final d = await db;
    var sql = 'SELECT * FROM $table';
    if (where != null) sql += ' WHERE $where';
    if (orderBy != null) sql += ' ORDER BY $orderBy';
    return d.rawQuery(sql, whereArgs);
  }

  Future<void> insert(String table, Map<String, dynamic> values,
      {ConflictAlgorithm? conflictAlgorithm}) async {
    final d = await db;
    final cols = values.keys.toList();
    final placeholders = List.filled(cols.length, '?').join(', ');
    final conflict =
        conflictAlgorithm == ConflictAlgorithm.replace ? 'OR REPLACE' : '';
    await d.execute(
      'INSERT $conflict INTO $table (${cols.join(', ')}) VALUES ($placeholders)',
      cols.map((c) => values[c]).toList(),
    );
  }

  Future<void> update(String table, Map<String, dynamic> values,
      {String? where, List<Object?>? whereArgs}) async {
    final d = await db;
    final sets = values.keys.map((k) => '$k = ?').join(', ');
    final args = [...values.values, ...?whereArgs];
    var sql = 'UPDATE $table SET $sets';
    if (where != null) sql += ' WHERE $where';
    await d.execute(sql, args);
  }

  Future<void> delete(String table,
      {String? where, List<Object?>? whereArgs}) async {
    final d = await db;
    var sql = 'DELETE FROM $table';
    if (where != null) sql += ' WHERE $where';
    await d.execute(sql, whereArgs);
  }
}
