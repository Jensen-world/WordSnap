import 'dart:convert';
import 'package:web/web.dart' as web;

class WebStorage {
  static final WebStorage _instance = WebStorage._();
  factory WebStorage() => _instance;
  WebStorage._();

  List<Map<String, dynamic>> _notebooks = [];
  List<Map<String, dynamic>> _words = [];
  List<Map<String, dynamic>> _reviewSessions = [];
  int _nextNotebookId = 1;
  int _nextWordId = 1;
  int _nextReviewSessionId = 1;
  bool _loaded = false;

  void _load() {
    if (_loaded) return;
    _loaded = true;
    try {
      final nbJson = web.window.localStorage.getItem('ws_notebooks');
      if (nbJson != null) {
        _notebooks = (jsonDecode(nbJson) as List).cast<Map<String, dynamic>>();
        for (final n in _notebooks) {
          final id = n['id'] as int;
          if (id >= _nextNotebookId) _nextNotebookId = id + 1;
        }
      }
      final wJson = web.window.localStorage.getItem('ws_words');
      if (wJson != null) {
        _words = (jsonDecode(wJson) as List).cast<Map<String, dynamic>>();
        for (final w in _words) {
          final id = w['id'] as int;
          if (id >= _nextWordId) _nextWordId = id + 1;
        }
      }
      final rsJson = web.window.localStorage.getItem('ws_review_sessions');
      if (rsJson != null) {
        _reviewSessions = (jsonDecode(rsJson) as List).cast<Map<String, dynamic>>();
        for (final s in _reviewSessions) {
          final id = s['id'] as int;
          if (id >= _nextReviewSessionId) _nextReviewSessionId = id + 1;
        }
      }
    } catch (_) {
      _notebooks = [];
      _words = [];
      _reviewSessions = [];
    }
    if (_notebooks.isEmpty) {
      final now = DateTime.now().toIso8601String();
      _notebooks.add({
        'id': _nextNotebookId++,
        'name': '拾词集',
        'isDefault': 1,
        'dailyNewWordLimit': 10,
        'createdAt': now,
      });
      _saveNotebooks();
    }
  }

  void _saveNotebooks() {
    web.window.localStorage.setItem('ws_notebooks', jsonEncode(_notebooks));
  }

  void _saveWords() {
    web.window.localStorage.setItem('ws_words', jsonEncode(_words));
  }

  void _saveReviewSessions() {
    web.window.localStorage.setItem('ws_review_sessions', jsonEncode(_reviewSessions));
  }

  // ── Notebooks ──

  List<Map<String, dynamic>> getNotebooks({String? orderBy}) {
    _load();
    final list = List<Map<String, dynamic>>.from(_notebooks);
    if (orderBy == 'isDefault DESC, createdAt DESC') {
      list.sort((a, b) {
        final aDef = a['isDefault'] as int;
        final bDef = b['isDefault'] as int;
        if (aDef != bDef) return bDef.compareTo(aDef);
        return (b['createdAt'] as String).compareTo(a['createdAt'] as String);
      });
    }
    return list;
  }

  int insertNotebook(Map<String, dynamic> map) {
    _load();
    final id = _nextNotebookId++;
    final row = Map<String, dynamic>.from(map);
    row['id'] = id;
    _notebooks.add(row);
    _saveNotebooks();
    return id;
  }

  void updateNotebook(Map<String, dynamic> map) {
    _load();
    final id = map['id'] as int;
    final idx = _notebooks.indexWhere((n) => n['id'] == id);
    if (idx >= 0) _notebooks[idx] = Map<String, dynamic>.from(map);
    _saveNotebooks();
  }

  void deleteNotebook(int id) {
    _load();
    _notebooks.removeWhere((n) => n['id'] == id);
    _words.removeWhere((w) => w['notebookId'] == id);
    _saveNotebooks();
    _saveWords();
  }

  // ── Words ──

  List<Map<String, dynamic>> queryWords({
    int? notebookId,
    bool? isNew,
    bool? isMastered,
    String? orderBy,
  }) {
    _load();
    var result = List<Map<String, dynamic>>.from(_words);
    if (notebookId != null) {
      result = result.where((w) => w['notebookId'] == notebookId).toList();
    }
    if (isNew != null) {
      result = result.where((w) => (w['isNew'] as int) == (isNew ? 1 : 0)).toList();
    }
    if (isMastered != null) {
      result = result.where((w) => (w['isMastered'] as int) == (isMastered ? 1 : 0)).toList();
    }
    if (orderBy == 'learnedAt DESC') {
      result.sort((a, b) => (b['learnedAt'] as String).compareTo(a['learnedAt'] as String));
    }
    return result;
  }

  Map<String, dynamic>? getWordById(int id) {
    _load();
    try {
      return _words.firstWhere((w) => w['id'] == id);
    } catch (_) {
      return null;
    }
  }

  int insertWord(Map<String, dynamic> map) {
    _load();
    final id = _nextWordId++;
    final row = Map<String, dynamic>.from(map);
    row['id'] = id;
    _words.add(row);
    _saveWords();
    return id;
  }

  void updateWord(Map<String, dynamic> map) {
    _load();
    final id = map['id'] as int;
    final idx = _words.indexWhere((w) => w['id'] == id);
    if (idx >= 0) _words[idx] = Map<String, dynamic>.from(map);
    _saveWords();
  }

  void deleteWord(int id) {
    _load();
    _words.removeWhere((w) => w['id'] == id);
    _saveWords();
  }

  int countWords({int? notebookId, bool? isNew, bool? isMastered}) {
    _load();
    var result = List<Map<String, dynamic>>.from(_words);
    if (notebookId != null) {
      result = result.where((w) => w['notebookId'] == notebookId).toList();
    }
    if (isNew != null) {
      result = result.where((w) => (w['isNew'] as int) == (isNew ? 1 : 0)).toList();
    }
    if (isMastered != null) {
      result = result.where((w) => (w['isMastered'] as int) == (isMastered ? 1 : 0)).toList();
    }
    return result.length;
  }

  // ── Review Sessions ──

  Map<String, dynamic>? getReviewSession(String dateStr) {
    _load();
    try {
      return _reviewSessions.firstWhere((s) => s['date'] == dateStr);
    } catch (_) {
      return null;
    }
  }

  int insertReviewSession(Map<String, dynamic> map) {
    _load();
    final id = _nextReviewSessionId++;
    final row = Map<String, dynamic>.from(map);
    row['id'] = id;
    _reviewSessions.add(row);
    _saveReviewSessions();
    return id;
  }

  void updateReviewSession(Map<String, dynamic> map) {
    _load();
    final id = map['id'] as int;
    final idx = _reviewSessions.indexWhere((s) => s['id'] == id);
    if (idx >= 0) _reviewSessions[idx] = Map<String, dynamic>.from(map);
    _saveReviewSessions();
  }

  List<Map<String, dynamic>> getRecentReviewSessions(int days) {
    _load();
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final cutoffStr = cutoff.toIso8601String();
    return _reviewSessions
        .where((s) => (s['date'] as String).compareTo(cutoffStr) >= 0)
        .toList()
      ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
  }
}
