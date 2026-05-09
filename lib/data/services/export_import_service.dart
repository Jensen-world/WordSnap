import 'dart:convert';
import '../models/notebook.dart';
import '../models/word.dart';
import '../repositories/notebook_repository.dart'
  if (dart.library.js_interop) '../repositories/notebook_repository_web.dart';
import '../repositories/word_repository.dart'
  if (dart.library.js_interop) '../repositories/word_repository_web.dart';

class NotebookPreview {
  final String name;
  final bool exists;
  final int wordCount;
  final int newWordCount;
  final int existingWordCount;

  const NotebookPreview({
    required this.name,
    required this.exists,
    required this.wordCount,
    required this.newWordCount,
    required this.existingWordCount,
  });
}

class ImportPreview {
  final List<NotebookPreview> notebooks;
  final int totalNewWords;
  final int totalExistingWords;

  const ImportPreview({
    required this.notebooks,
    required this.totalNewWords,
    required this.totalExistingWords,
  });

  int get totalNotebooks => notebooks.length;
  int get newNotebookCount => notebooks.where((n) => !n.exists).length;
}

class ExportImportService {
  final NotebookRepository _notebookRepo;
  final WordRepository _wordRepo;

  ExportImportService(this._notebookRepo, this._wordRepo);

  Future<String> exportToJson() async {
    final notebooks = await _notebookRepo.getAll();
    final data = <String, dynamic>{
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'notebooks': <Map<String, dynamic>>[],
    };

    for (final nb in notebooks) {
      final words = await _wordRepo.getByNotebook(nb.id!);
      data['notebooks'].add({
        'name': nb.name,
        'isDefault': nb.isDefault,
        'dailyNewWordLimit': nb.dailyNewWordLimit,
        'words': words.map((w) => {
          'text': w.text,
          'phonetic': w.phonetic,
          'partOfSpeech': w.partOfSpeech,
          'definitions': w.definitions,
          'examples': w.examples,
          'contexts': w.contexts.map((c) => c.toJson()).toList(),
          'tags': w.tags,
          'isNew': w.isNew,
          'reviewCount': w.reviewCount,
          'learnedAt': w.learnedAt.toIso8601String(),
          'isMastered': w.isMastered,
          'createdAt': w.createdAt.toIso8601String(),
          'updatedAt': w.updatedAt.toIso8601String(),
        }).toList(),
      });
    }

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<ImportPreview> analyzeJson(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final notebooks = data['notebooks'] as List<dynamic>;
    final existingNotebooks = await _notebookRepo.getAll();
    final previews = <NotebookPreview>[];
    int totalNewWords = 0;
    int totalExistingWords = 0;

    for (final nbJson in notebooks) {
      final name = nbJson['name'] as String;
      final match = existingNotebooks.where((n) => n.name == name).firstOrNull;
      final words = nbJson['words'] as List<dynamic>? ?? [];
      int newCount = 0;
      int existCount = 0;

      if (match != null) {
        final existingWords = await _wordRepo.getByNotebook(match.id!);
        for (final wJson in words) {
          final text = wJson['text'] as String;
          if (existingWords.any((w) => w.text == text)) {
            existCount++;
          } else {
            newCount++;
          }
        }
      } else {
        newCount = words.length;
      }

      totalNewWords += newCount;
      totalExistingWords += existCount;
      previews.add(NotebookPreview(
        name: name,
        exists: match != null,
        wordCount: words.length,
        newWordCount: newCount,
        existingWordCount: existCount,
      ));
    }

    return ImportPreview(
      notebooks: previews,
      totalNewWords: totalNewWords,
      totalExistingWords: totalExistingWords,
    );
  }

  Future<Map<String, int>> importFromJson(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final notebooks = data['notebooks'] as List<dynamic>;
    int newWords = 0;
    int mergedNotebooks = 0;

    for (final nbJson in notebooks) {
      final name = nbJson['name'] as String;
      final existing = await _notebookRepo.getAll();
      final match = existing.where((n) => n.name == name).firstOrNull;

      int notebookId;
      if (match != null) {
        notebookId = match.id!;
        mergedNotebooks++;
      } else {
        final nb = Notebook(name: name, isDefault: nbJson['isDefault'] as bool, createdAt: DateTime.now());
        final created = await _notebookRepo.insert(nb);
        notebookId = created.id!;
      }

      final words = nbJson['words'] as List<dynamic>? ?? [];
      for (final wJson in words) {
        final text = wJson['text'] as String;
        final existingWords = await _wordRepo.getByNotebook(notebookId);
        if (existingWords.any((w) => w.text == text)) continue;

        final word = Word(
          notebookId: notebookId,
          text: text,
          phonetic: wJson['phonetic'] as String?,
          partOfSpeech: wJson['partOfSpeech'] as String?,
          definitions: (wJson['definitions'] as List<dynamic>?)?.cast<String>() ?? [],
          examples: (wJson['examples'] as List<dynamic>?)?.cast<String>() ?? [],
          tags: (wJson['tags'] as List<dynamic>?)?.cast<String>() ?? [],
          isNew: wJson['isNew'] as bool? ?? true,
          reviewCount: wJson['reviewCount'] as int? ?? 0,
          learnedAt: DateTime.parse(wJson['learnedAt'] as String),
          isMastered: wJson['isMastered'] as bool? ?? false,
          createdAt: DateTime.parse(wJson['createdAt'] as String),
          updatedAt: DateTime.parse(wJson['updatedAt'] as String),
        );
        await _wordRepo.insert(word);
        newWords++;
      }
    }

    return {'newWords': newWords, 'mergedNotebooks': mergedNotebooks};
  }
}
