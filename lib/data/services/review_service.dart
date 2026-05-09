import '../models/word.dart';
import '../repositories/word_repository.dart'
  if (dart.library.js_interop) '../repositories/word_repository_web.dart';

enum StudyMode { normal, transition, pureReview }

class ReviewService {
  static const int newPerReview = 10;
  static const int masterThreshold = 10;

  final WordRepository _wordRepo;

  ReviewService(this._wordRepo);

  Future<StudyMode> getMode(int notebookId) async {
    final newCount = await _wordRepo.getCount(notebookId: notebookId, isNew: true);
    if (newCount >= 10) return StudyMode.normal;
    if (newCount > 0) return StudyMode.transition;
    return StudyMode.pureReview;
  }

  Future<List<Word>> getTodayQueue(int notebookId, int dailyLimit) async {
    final newWords = await _wordRepo.getByNotebookAndStatus(notebookId, isNew: true);
    final reviewWords = await _wordRepo.getByNotebookAndStatus(notebookId, isNew: false, isMastered: false);

    final limitedNew = newWords.take(dailyLimit).toList();
    final sortedReview = reviewWords..sort((a, b) => a.learnedAt.compareTo(b.learnedAt));

    return _interleave(limitedNew, sortedReview);
  }

  Future<List<Word>> getPureReviewQueue(int notebookId) async {
    final words = await _wordRepo.getByNotebookAndStatus(notebookId, isMastered: false);
    words.sort((a, b) => a.learnedAt.compareTo(b.learnedAt));
    return words;
  }

  List<Word> _interleave(List<Word> newWords, List<Word> reviewWords) {
    final result = <Word>[];
    int ni = 0, ri = 0;
    while (ni < newWords.length || ri < reviewWords.length) {
      for (int i = 0; i < newPerReview && ni < newWords.length; i++) {
        result.add(newWords[ni++]);
      }
      if (ri < reviewWords.length) {
        result.add(reviewWords[ri++]);
      }
    }
    return result;
  }

  Future<Word> markCorrect(Word word) async {
    final newReviewCount = word.reviewCount + 1;
    final isMastered = newReviewCount >= masterThreshold;
    final updated = word.copyWith(
      isNew: false,
      reviewCount: newReviewCount,
      isMastered: isMastered,
      updatedAt: DateTime.now(),
    );
    await _wordRepo.update(updated);
    return updated;
  }

  Future<Word> markIncorrect(Word word) async {
    final updated = word.copyWith(
      isNew: false,
      reviewCount: 0,
      learnedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _wordRepo.update(updated);
    return updated;
  }

  Future<Word> markNewCorrect(Word word) async {
    final updated = word.copyWith(
      isNew: false,
      reviewCount: 1,
      learnedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _wordRepo.update(updated);
    return updated;
  }
}
