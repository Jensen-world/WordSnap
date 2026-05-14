import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import 'dictionary_result.dart';
import 'llm_dictionary_service.dart';
import 'tatoeba_service.dart';
import '../repositories/config_repository.dart';

class DictionaryService {
  static const _assetPath = 'assets/ecdict_slim.db';
  Database? _db;
  final _llm = LlmDictionaryService();
  final _tatoeba = TatoebaService();
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

    // 2. ECDICT first — always returns definitions
    final ecdictResult = await _lookupEcdict(clean);

    // 3. Try LLM enrichment
    final apiKey = await _config.get('llm_api_key');
    if (apiKey != null && apiKey.isNotEmpty) {
      final baseUrl = await _config.get('llm_base_url') ?? ConfigRepository.defaultBaseUrl;
      final model = await _config.get('llm_model') ?? ConfigRepository.defaultModel;

      // Full LLM lookup (definitions + examples)
      final llmResult = await _llm.lookup(clean, baseUrl: baseUrl, apiKey: apiKey, model: model);
      if (llmResult != null) {
        await _putCache(llmResult);
        return llmResult;
      }

      // LLM main lookup failed — if ECDICT has no examples, try a lightweight call just for the example
      if (ecdictResult != null &&
          (ecdictResult.exampleSentence == null || ecdictResult.exampleSentence!.isEmpty)) {
        final example = await _llm.lookupExample(clean, baseUrl: baseUrl, apiKey: apiKey, model: model);
        if (example != null) {
          return DictionaryResult(
            word: ecdictResult.word,
            phonetic: ecdictResult.phonetic,
            translation: ecdictResult.translation,
            meanings: ecdictResult.meanings,
            exchange: ecdictResult.exchange,
            tag: ecdictResult.tag,
            exampleSentence: example['sentence'],
            exampleTranslation: example['translation'],
          );
        }
      }
    }

    // 4. Tatoeba offline fallback — if still no examples
    if (ecdictResult != null &&
        (ecdictResult.exampleSentence == null || ecdictResult.exampleSentence!.isEmpty)) {
      final tatoebaExample = await _tatoeba.lookup(clean);
      if (tatoebaExample != null) {
        return DictionaryResult(
          word: ecdictResult.word,
          phonetic: ecdictResult.phonetic,
          translation: ecdictResult.translation,
          meanings: ecdictResult.meanings,
          exchange: ecdictResult.exchange,
          tag: ecdictResult.tag,
          exampleSentence: tatoebaExample['sentence'],
          exampleTranslation: tatoebaExample['translation'],
        );
      }
    }

    return ecdictResult;
  }

  Future<DictionaryResult?> _lookupEcdict(String word) async {
    try {
      final db = await _getDb();
      var rows = await db.query(
        'stardict',
        where: 'word = ?',
        whereArgs: [word],
        limit: 1,
      );
      if (rows.isNotEmpty) return DictionaryResult.fromEcdict(rows.first);

      // Exact match failed — try reverse inflection lookup.
      // Exchange format: key:value/... e.g. "0:run/1:ran/i:running/s:runs"
      rows = await db.query(
        'stardict',
        where: "exchange LIKE ? OR exchange LIKE ?",
        whereArgs: ['%:$word/%', '%:$word'],
        limit: 1,
      );
      if (rows.isEmpty) return null;

      final entry = rows.first;
      // If the entry has a base form (0:xxx), use it; otherwise use the entry word itself.
      final exchange = (entry['exchange'] as String?) ?? '';
      final baseMatch = RegExp(r'(?:^|/)0:([^/]+)').firstMatch(exchange);
      final baseWord = baseMatch?.group(1) ?? entry['word'] as String;

      if (baseWord == word) {
        return DictionaryResult.fromEcdict(entry);
      }

      // Look up the base word for full definition, but preserve original search word.
      rows = await db.query(
        'stardict',
        where: 'word = ?',
        whereArgs: [baseWord],
        limit: 1,
      );
      if (rows.isEmpty) return DictionaryResult.fromEcdict(entry);

      final baseResult = DictionaryResult.fromEcdict(rows.first);
      return DictionaryResult(
        word: word,
        phonetic: baseResult.phonetic,
        translation: baseResult.translation,
        meanings: baseResult.meanings,
        exchange: baseResult.exchange,
        tag: baseResult.tag,
        exampleSentence: baseResult.exampleSentence,
        exampleTranslation: baseResult.exampleTranslation,
      );
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
