import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class TatoebaService {
  static const _assetPath = 'assets/tatoeba_slim.db';
  Database? _db;

  Future<Database> _getDb() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'tatoeba_slim.db');
    if (!await File(dbPath).exists()) {
      final data = await rootBundle.load(_assetPath);
      await File(dbPath).writeAsBytes(data.buffer.asUint8List());
    }
    _db = await openDatabase(dbPath, readOnly: true);
    return _db!;
  }

  /// Returns the first matching example for a word, or null.
  /// Falls back to LIKE search on the sentence column if exact word match fails.
  Future<Map<String, String>?> lookup(String word) async {
    final clean = word.trim().toLowerCase();
    if (clean.isEmpty) return null;

    try {
      final db = await _getDb();
      // 1. Exact word match (fast, indexed)
      var rows = await db.query(
        'tatoeba',
        columns: ['sentence', 'translation'],
        where: 'word = ?',
        whereArgs: [clean],
        limit: 1,
      );
      // 2. Fallback: search the sentence column for the word
      if (rows.isEmpty) {
        rows = await db.query(
          'tatoeba',
          columns: ['sentence', 'translation'],
          where: 'sentence LIKE ? OR sentence LIKE ? OR sentence LIKE ?',
          whereArgs: ['% $clean %', '$clean %', '% $clean'],
          limit: 1,
        );
      }
      if (rows.isEmpty) return null;
      return {
        'sentence': rows.first['sentence'] as String,
        'translation': rows.first['translation'] as String,
      };
    } catch (_) {
      return null;
    }
  }
}
