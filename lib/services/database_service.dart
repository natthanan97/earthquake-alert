import 'dart:developer';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/earthquake.dart';

class DatabaseService {
  static const _dbName = 'earthquake_cache.db';
  static const _version = 1;
  static const _table = 'earthquakes';
  static const _maxCached = 500;

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _version,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE $_table (
          id        TEXT PRIMARY KEY,
          latitude  REAL NOT NULL,
          longitude REAL NOT NULL,
          magnitude REAL NOT NULL,
          depth     REAL NOT NULL,
          location  TEXT NOT NULL,
          time_ms   INTEGER NOT NULL,
          max_scale INTEGER NOT NULL,
          tsunami   INTEGER NOT NULL,
          source    TEXT NOT NULL,
          country_code TEXT NOT NULL,
          country_flag TEXT NOT NULL,
          country_name TEXT NOT NULL
        )
      '''),
    );
  }

  Future<void> insertEarthquakes(List<Earthquake> earthquakes) async {
    if (earthquakes.isEmpty) return;
    final db = await _database;
    final batch = db.batch();
    for (final eq in earthquakes) {
      batch.insert(
        _table,
        _toRow(eq),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    await _prune(db);
    log('Inserted ${earthquakes.length} earthquakes', name: 'DatabaseService');
  }

  Future<List<Earthquake>> loadRecent({int limit = 200}) async {
    try {
      final db = await _database;
      final rows = await db.query(
        _table,
        orderBy: 'time_ms DESC',
        limit: limit,
      );
      return rows.map(_fromRow).toList();
    } catch (e) {
      log('loadRecent error: $e', name: 'DatabaseService');
      return [];
    }
  }

  Future<void> _prune(Database db) async {
    await db.execute('''
      DELETE FROM $_table WHERE id NOT IN (
        SELECT id FROM $_table ORDER BY time_ms DESC LIMIT $_maxCached
      )
    ''');
  }

  Map<String, Object?> _toRow(Earthquake eq) => {
        'id': eq.dedupKey,
        'latitude': eq.latitude,
        'longitude': eq.longitude,
        'magnitude': eq.magnitude,
        'depth': eq.depth,
        'location': eq.location,
        'time_ms': eq.time.millisecondsSinceEpoch,
        'max_scale': eq.maxScale,
        'tsunami': eq.tsunami ? 1 : 0,
        'source': eq.source.name,
        'country_code': eq.countryCode,
        'country_flag': eq.countryFlag,
        'country_name': eq.countryName,
      };

  Earthquake _fromRow(Map<String, Object?> row) => Earthquake(
        latitude: row['latitude'] as double,
        longitude: row['longitude'] as double,
        magnitude: row['magnitude'] as double,
        depth: row['depth'] as double,
        location: row['location'] as String,
        time: DateTime.fromMillisecondsSinceEpoch(
          row['time_ms'] as int,
          isUtc: true,
        ),
        maxScale: row['max_scale'] as int,
        tsunami: (row['tsunami'] as int) == 1,
        source: EarthquakeSource.values.firstWhere(
          (s) => s.name == row['source'],
          orElse: () => EarthquakeSource.usgs,
        ),
        countryCode: row['country_code'] as String,
        countryFlag: row['country_flag'] as String,
        countryName: row['country_name'] as String,
      );

  Future<void> dispose() async {
    await _db?.close();
    _db = null;
  }
}
