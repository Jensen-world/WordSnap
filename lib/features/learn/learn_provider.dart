import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notebook.dart';
import '../../data/models/word.dart';
import '../wordbook/wordbook_provider.dart';

final learnStateProvider = StateNotifierProvider<LearnNotifier, LearnState>((ref) {
  return LearnNotifier(ref);
});

class LearnState {
  final List<Notebook> notebooks;
  final int? currentNotebookId;
  final Notebook? currentNotebook;
  final int newWords; // today's session quota
  final int reviewWords; // today's session quota
  final int dbNewWords; // database count
  final int dbReviewWords; // database count
  final int masteredWords;
  final int totalWords;
  final int dailyLimit;
  final int estimatedDays;
  final Word? dailyWord;
  final bool loading;
  final String? errorMessage;

  const LearnState({
    this.notebooks = const [],
    this.currentNotebookId,
    this.currentNotebook,
    this.newWords = 0,
    this.reviewWords = 0,
    this.dbNewWords = 0,
    this.dbReviewWords = 0,
    this.masteredWords = 0,
    this.totalWords = 0,
    this.dailyLimit = 0,
    this.estimatedDays = 0,
    this.dailyWord,
    this.loading = true,
    this.errorMessage,
  });

  LearnState copyWith({
    List<Notebook>? notebooks,
    int? currentNotebookId,
    Notebook? currentNotebook,
    int? newWords,
    int? reviewWords,
    int? dbNewWords,
    int? dbReviewWords,
    int? masteredWords,
    int? totalWords,
    int? dailyLimit,
    int? estimatedDays,
    Word? dailyWord,
    bool? loading,
    String? errorMessage,
  }) => LearnState(
    notebooks: notebooks ?? this.notebooks,
    currentNotebookId: currentNotebookId ?? this.currentNotebookId,
    currentNotebook: currentNotebook ?? this.currentNotebook,
    newWords: newWords ?? this.newWords,
    reviewWords: reviewWords ?? this.reviewWords,
    dbNewWords: dbNewWords ?? this.dbNewWords,
    dbReviewWords: dbReviewWords ?? this.dbReviewWords,
    masteredWords: masteredWords ?? this.masteredWords,
    totalWords: totalWords ?? this.totalWords,
    dailyLimit: dailyLimit ?? this.dailyLimit,
    estimatedDays: estimatedDays ?? this.estimatedDays,
    dailyWord: dailyWord ?? this.dailyWord,
    loading: loading ?? this.loading,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  int get remainingNewWords => totalWords - masteredWords;
  double get masteredProgress => totalWords > 0 ? masteredWords / totalWords : 0;
}

class LearnNotifier extends StateNotifier<LearnState> {
  final Ref _ref;

  LearnNotifier(this._ref) : super(const LearnState());

  Future<void> load() async {
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      final nbRepo = _ref.read(notebookRepoProvider);
      final wordRepo = _ref.read(wordRepoProvider);
      final reviewRepo = _ref.read(reviewRepoProvider);
      final notebooks = await nbRepo.getAll();
      final currentId = state.currentNotebookId ?? notebooks.firstOrNull?.id;
      final currentNb = notebooks.where((n) => n.id == currentId).firstOrNull ?? notebooks.firstOrNull;
      if (currentNb == null) {
        state = state.copyWith(loading: false);
        return;
      }

      final dbNewCount = await wordRepo.getCount(notebookId: currentNb.id, isNew: true);
      final masteredWords = await wordRepo.getCount(notebookId: currentNb.id, isMastered: true);
      final totalWords = await wordRepo.getCount(notebookId: currentNb.id);
      final dbReviewCount = totalWords - dbNewCount - masteredWords;
      final dailyLimit = currentNb.dailyNewWordLimit;

      // Today's session counts
      final today = await reviewRepo.getToday();
      final learnedNew = today?.newWordsLearned ?? 0;
      final learnedReview = (today?.reviewWordsCorrect ?? 0) + (today?.reviewWordsWrong ?? 0);

      // Today's remaining quota: new words + review words per 10:1 ratio
      final todayNewWords = (dailyLimit - learnedNew).clamp(0, dailyLimit);
      final todayReviewBudget = (todayNewWords / 10).ceil();
      final todayReviewWords = (todayReviewBudget - learnedReview).clamp(0, todayReviewBudget);
      print('DEBUG todayNewWords=$todayNewWords todayReviewWords=$todayReviewWords learnedNew=$learnedNew learnedReview=$learnedReview');

      final remaining = totalWords - masteredWords;
      final estimatedDays = dailyLimit > 0 ? (remaining / dailyLimit).ceil() : 0;

      // Daily word: pick from current notebook first, fall back to any notebook
      Word? dailyWord;
      final now = DateTime.now();
      final seed = now.year * 400 + now.month * 40 + now.day;

      Future<Word?> pickDaily(int nbId) async {
        final words = await wordRepo.getByNotebook(nbId);
        if (words.isNotEmpty) return words[seed % words.length];
        return null;
      }

      dailyWord = await pickDaily(currentNb.id!);
      if (dailyWord == null) {
        for (final nb in notebooks) {
          if (nb.id == currentNb.id) continue;
          dailyWord = await pickDaily(nb.id!);
          if (dailyWord != null) break;
        }
      }

      state = state.copyWith(
        notebooks: notebooks,
        currentNotebookId: currentId,
        currentNotebook: currentNb,
        newWords: todayNewWords,
        reviewWords: todayReviewWords,
        dbNewWords: dbNewCount,
        dbReviewWords: dbReviewCount,
        masteredWords: masteredWords,
        totalWords: totalWords,
        dailyLimit: dailyLimit,
        estimatedDays: estimatedDays,
        dailyWord: dailyWord,
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(loading: false, errorMessage: '加载失败，请检查数据库');
    }
  }

  void setCurrentNotebook(int id) {
    state = state.copyWith(currentNotebookId: id);
    load();
  }

  Future<void> setDailyLimit(int limit) async {
    final nb = state.currentNotebook;
    if (nb == null) return;
    final updated = nb.copyWith(dailyNewWordLimit: limit);
    await _ref.read(notebookRepoProvider).update(updated);
    load();
  }
}
