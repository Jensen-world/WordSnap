import '../models/word.dart';
import '../storage/web_storage.dart';

class WordRepository {
  final _store = WebStorage();

  Future<List<Word>> getByNotebook(int notebookId) async {
    return _store.queryWords(notebookId: notebookId, orderBy: 'learnedAt DESC').map((m) => Word.fromMap(m)).toList();
  }

  Future<List<Word>> getByNotebookAndStatus(int notebookId, {bool? isNew, bool? isMastered}) async {
    return _store.queryWords(notebookId: notebookId, isNew: isNew, isMastered: isMastered, orderBy: 'learnedAt DESC').map((m) => Word.fromMap(m)).toList();
  }

  Future<Word?> getById(int id) async {
    final w = _store.getWordById(id);
    if (w == null) return null;
    return Word.fromMap(w);
  }

  Future<Word> insert(Word word) async {
    final id = _store.insertWord(word.toMap());
    return word.copyWith(id: id);
  }

  Future<int> insertBatch(List<Word> words) async {
    var count = 0;
    for (final word in words) {
      _store.insertWord(word.toMap());
      count++;
    }
    return count;
  }

  Future<void> update(Word word) async {
    _store.updateWord(word.toMap());
  }

  Future<void> delete(int id) async {
    _store.deleteWord(id);
  }

  Future<bool> existsByText(String text) async {
    final all = _store.queryWords();
    return all.any((w) => (w['text'] as String).toLowerCase().trim() == text.toLowerCase().trim());
  }

  Future<bool> existsByTextInNotebook(String text, int notebookId) async {
    final all = _store.queryWords(notebookId: notebookId);
    return all.any((w) => (w['text'] as String).toLowerCase().trim() == text.toLowerCase().trim());
  }

  Future<int> getCount({int? notebookId, bool? isNew, bool? isMastered}) async {
    return _store.countWords(notebookId: notebookId, isNew: isNew, isMastered: isMastered);
  }
}
