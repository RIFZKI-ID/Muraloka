import 'dart:async';

import 'package:muraloka/data/models/local_data_model.dart';
import 'package:sqflite/sqflite.dart';

class PaintDatabaseHelper {
  static PaintDatabaseHelper? _databaseHelper;
  PaintDatabaseHelper._instance() {
    _databaseHelper = this;
  }

  factory PaintDatabaseHelper() =>
      _databaseHelper ?? PaintDatabaseHelper._instance();

  static Database? _database;

  Future<Database?> get database async {
    if (_database == null) {
      _database = await _initDb();
    }
    return _database;
  }

  static const String _tableBookmark = 'paint_bookmark';

  Future<Database> _initDb() async {
    final path = await getDatabasesPath();
    final databasePath = '$path/local/muraloka.db';

    var db = await openDatabase(databasePath, version: 1, onCreate: _onCreate);
    return db;
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE  $_tableBookmark (
        id INTEGER PRIMARY KEY,
        title TEXT,
        description TEXT,
        posterPath TEXT
      );
    ''');
  }

  // TODO: fix insert bookmark
  // Future<int> insertBookmark(LocalDataModel data) async {
  //   final db = await database;
  //   return await db!.insert(_tableBookmark, data.toJson());
  // }

  //TOdo: fix remove bookmark
  // Future<int> removeBookmark(LocalDataModel data) async {
  //   final db = await database;
  //   return await db!.delete(
  //     _tableBookmark,
  //     where: 'id = ?',
  //     whereArgs: [data.id],
  //   );
  // }

  Future<Map<String, dynamic>?> getBookmarkById(int id) async {
    final db = await database;
    final results = await db!.query(
      _tableBookmark,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      return results.first;
    } else {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getBookmarkPaint() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db!.query(_tableBookmark);

    return results;
  }
}
