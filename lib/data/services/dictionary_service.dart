import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import 'dictionary_result.dart';
import 'llm_dictionary_service.dart';
import '../repositories/config_repository.dart';

class DictionaryService {
  static const _assetPath = 'assets/ecdict_slim.db';
  Database? _db;
  final _llm = LlmDictionaryService();
  final _config = ConfigRepository();

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

    // 1. Check local cache
    final cached = await _getCached(clean);
    if (cached != null) return cached;

    // 2. Try LLM
    final apiKey = await _config.get('llm_api_key');
    if (apiKey != null && apiKey.isNotEmpty) {
      final baseUrl = await _config.get('llm_base_url') ?? ConfigRepository.defaultBaseUrl;
      final model = await _config.get('llm_model') ?? ConfigRepository.defaultModel;
      final result = await _llm.lookup(clean, baseUrl: baseUrl, apiKey: apiKey, model: model);
      if (result != null) {
        await _putCache(result);
        return result;
      }
    }

    // 3. Fallback to ECDICT (not cached — so LLM gets another chance later)
    return _lookupEcdict(clean);
  }

  Future<DictionaryResult?> _lookupEcdict(String word) async {
    try {
      final db = await _getDb();
      final rows = await db.query(
        'stardict',
        where: 'word = ?',
        whereArgs: [word],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return DictionaryResult.fromEcdict(rows.first);
    } catch (_) {
      return null;
    }
  }

  Future<DictionaryResult?> _getCached(String word) async {
    try {
      final db = await DatabaseHelper.instance.db;
      final rows = await db.query(
        'dictionary_cache',
        where: 'word = ?',
        whereArgs: [word],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final cached = DictionaryResult.fromCache(rows.first);
      // Skip stale cache entries that lack example sentences —
      // the old LLM prompt didn't require them, so re-query via LLM.
      if (cached.exampleSentence == null || cached.exampleSentence!.isEmpty) {
        return null;
      }
      return cached;
    } catch (_) {
      return null;
    }
  }

  Future<void> _putCache(DictionaryResult result) async {
    try {
      final db = await DatabaseHelper.instance.db;
      await db.insert(
        'dictionary_cache',
        result.toCacheMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }
}
