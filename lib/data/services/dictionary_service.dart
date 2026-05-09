import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dictionary_result.dart';

class DictionaryService {
  static const _assetPath = 'assets/ecdict_slim.db';
  Database? _db;

  Future<Database> _getDb() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'ecdict_slim.db');
    if (!await File(dbPath).exists()) {
      final data = await rootBundle.load(_assetPath);
      await File(dbPath).writeAsBytes(data.buffer.asUint8List());
    }
    _db = await openDatabase(dbPath, readOnly: true);
    return _db!;
  }

  Future<DictionaryResult?> lookup(String word) async {
    final clean = word.trim().toLowerCase();
    if (clean.isEmpty) return null;
    try {
      final db = await _getDb();
      final rows = await db.query(
        'stardict',
        where: 'word = ?',
        whereArgs: [clean],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return DictionaryResult.fromEcdict(rows.first);
    } catch (_) {
      return null;
    }
  }
}
