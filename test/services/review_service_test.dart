import 'package:flutter_test/flutter_test.dart';
import 'package:wordsnap/data/models/word.dart';
import 'package:wordsnap/data/repositories/word_repository.dart';
import 'package:wordsnap/data/services/review_service.dart';

class FakeWordRepository implements WordRepository {
  final List<Word> _words = [];
  int _nextId = 1;

  void seed(Iterable<Word> words) {
    for (final w in words) {
      _words.add(w.copyWith(id: w.id ?? _nextId++));
    }
  }

  @override
  Future<List<Word>> getByNotebook(int notebookId) async =>
      _words.where((w) => w.notebookId == notebookId).toList();

  @override
  Future<List<Word>> getByNotebookAndStatus(int notebookId, {bool? isNew, bool? isMastered}) async {
    var filtered = _words.where((w) => w.notebookId == notebookId);
    if (isNew != null) {
      filtered = filtered.where((w) => w.isNew == isNew);
    }
    if (isMastered != null) {
      filtered = filtered.where((w) => w.isMastered == isMastered);
    }
    return filtered.toList();
  }

  @override
  Future<Word?> getById(int id) async {
    try { return _words.firstWhere((w) => w.id == id); }
    catch (_) { return null; }
  }

  @override
  Future<Word> insert(Word word) async {
    final w = word.copyWith(id: _nextId++);
    _words.add(w);
    return w;
  }

  @override
  Future<int> insertBatch(List<Word> words) async {
    var count = 0;
    for (final word in words) {
      _words.add(word.copyWith(id: _nextId++));
      count++;
    }
    return count;
  }

  @override
  Future<void> update(Word word) async {
    final idx = _words.indexWhere((w) => w.id == word.id);
    if (idx != -1) _words[idx] = word;
  }

  @override
  Future<void> delete(int id) async {
    _words.removeWhere((w) => w.id == id);
  }

  @override
  Future<bool> existsByText(String text) async {
    return _words.any((w) => w.text.toLowerCase().trim() == text.toLowerCase().trim());
  }

  @override
  Future<int> getCount({int? notebookId, bool? isNew, bool? isMastered}) async {
    var filtered = _words.where((_) => true);
    if (notebookId != null) filtered = filtered.where((w) => w.notebookId == notebookId);
    if (isNew != null) filtered = filtered.where((w) => w.isNew == isNew);
    if (isMastered != null) filtered = filtered.where((w) => w.isMastered == isMastered);
    return filtered.length;
  }
}

Word _newWord({int id = 0, int nb = 1, String text = 'word'}) {
  final now = DateTime.now();
  return Word(
    id: id,
    notebookId: nb,
    text: text,
    isNew: true,
    reviewCount: 0,
    isMastered: false,
    learnedAt: now,
    createdAt: now,
    updatedAt: now,
  );
}

Word _reviewWord({int id = 0, int nb = 1, String text = 'review', int count = 3}) {
  final now = DateTime.now();
  return Word(
    id: id,
    notebookId: nb,
    text: text,
    isNew: false,
    reviewCount: count,
    isMastered: false,
    learnedAt: now.subtract(Duration(days: count)),
    createdAt: now,
    updatedAt: now,
  );
}

Word _masteredWord({int id = 0, int nb = 1, String text = 'mastered'}) {
  final now = DateTime.now();
  return Word(
    id: id,
    notebookId: nb,
    text: text,
    isNew: false,
    reviewCount: 10,
    isMastered: true,
    learnedAt: now.subtract(const Duration(days: 10)),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeWordRepository repo;
  late ReviewService service;

  setUp(() {
    repo = FakeWordRepository();
    service = ReviewService(repo);
  });

  group('getMode', () {
    test('returns normal when ≥10 new words', () async {
      repo.seed(List.generate(10, (i) => _newWord(text: 'new$i')));
      expect(await service.getMode(1), StudyMode.normal);
    });

    test('returns transition when 1-9 new words', () async {
      repo.seed(List.generate(3, (i) => _newWord(text: 'new$i')));
      expect(await service.getMode(1), StudyMode.transition);
    });

    test('returns pureReview when 0 new words', () async {
      repo.seed([_reviewWord()]);
      expect(await service.getMode(1), StudyMode.pureReview);
    });
  });

  group('getTodayQueue', () {
    test('interleaves 10 new : 1 review', () async {
      repo.seed([
        ...List.generate(20, (i) => _newWord(text: 'n$i')),
        ...List.generate(5, (i) => _reviewWord(text: 'r$i')),
      ]);
      final queue = await service.getTodayQueue(1, 10);
      // 10 new words (dailyLimit), then all 5 review words appended.
      // Pattern: n0-n9 (10 new), r0, r1, r2, r3, r4 = 15 words
      expect(queue.length, 15);
      expect(queue[0].text, 'n0');
      expect(queue[9].text, 'n9');
      expect(queue[10].text, 'r0');
      expect(queue[14].text, 'r4');
    });

    test('respects dailyLimit', () async {
      repo.seed(List.generate(20, (i) => _newWord(text: 'n$i')));
      final queue = await service.getTodayQueue(1, 5);
      expect(queue.length, 5);
      expect(queue.every((w) => w.isNew), true);
    });

    test('sorts review words by learnedAt', () async {
      final now = DateTime.now();
      repo.seed([
        _newWord(text: 'n0'),
        // oldest first in review
        Word(id: 2, notebookId: 1, text: 'oldest', isNew: false, reviewCount: 2,
            isMastered: false, learnedAt: now.subtract(const Duration(days: 30)),
            createdAt: now, updatedAt: now),
        Word(id: 3, notebookId: 1, text: 'newest', isNew: false, reviewCount: 5,
            isMastered: false, learnedAt: now.subtract(const Duration(days: 1)),
            createdAt: now, updatedAt: now),
      ]);
      final queue = await service.getTodayQueue(1, 1);
      // Pattern: 1 new, 1 review (oldest), ...
      expect(queue[1].text, 'oldest');
    });
  });

  group('getPureReviewQueue', () {
    test('returns all non-mastered words sorted by learnedAt', () async {
      final now = DateTime.now();
      repo.seed([
        _masteredWord(id: 1),
        Word(id: 2, notebookId: 1, text: 'older', isNew: false, reviewCount: 3,
            isMastered: false, learnedAt: now.subtract(const Duration(days: 20)),
            createdAt: now, updatedAt: now),
        Word(id: 3, notebookId: 1, text: 'newer', isNew: false, reviewCount: 5,
            isMastered: false, learnedAt: now.subtract(const Duration(days: 2)),
            createdAt: now, updatedAt: now),
      ]);
      final queue = await service.getPureReviewQueue(1);
      expect(queue.length, 2); // mastered excluded
      expect(queue[0].text, 'older');
      expect(queue[1].text, 'newer');
    });
  });

  group('markCorrect', () {
    test('increments reviewCount by 1', () async {
      final word = _reviewWord(id: 1, count: 5);
      repo.seed([word]);
      final updated = await service.markCorrect(word);
      expect(updated.reviewCount, 6);
      expect(updated.isNew, false);
    });

    test('masters word at threshold 10', () async {
      final word = _reviewWord(id: 1, count: 9);
      repo.seed([word]);
      final updated = await service.markCorrect(word);
      expect(updated.reviewCount, 10);
      expect(updated.isMastered, true);
    });

    test('persists to repository', () async {
      final word = _reviewWord(id: 1, count: 3);
      repo.seed([word]);
      await service.markCorrect(word);
      final saved = await repo.getById(1);
      expect(saved!.reviewCount, 4);
    });
  });

  group('markIncorrect', () {
    test('resets reviewCount to 0', () async {
      final word = _reviewWord(id: 1, count: 7);
      repo.seed([word]);
      final updated = await service.markIncorrect(word);
      expect(updated.reviewCount, 0);
      expect(updated.isNew, false);
    });
  });

  group('markNewCorrect', () {
    test('marks isNew false and reviewCount 1', () async {
      final word = _newWord(id: 1);
      repo.seed([word]);
      final updated = await service.markNewCorrect(word);
      expect(updated.isNew, false);
      expect(updated.reviewCount, 1);
      expect(updated.isMastered, false);
    });
  });
}
