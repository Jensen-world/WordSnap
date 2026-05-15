import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notebook.dart';
import '../../data/models/word.dart';
import '../../data/repositories/config_repository.dart';
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
  final int dailyWordIndex;
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
    this.dailyWordIndex = 0,
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
    int? dailyWordIndex,
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
    dailyWordIndex: dailyWordIndex ?? this.dailyWordIndex,
    loading: loading ?? this.loading,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  int get remainingNewWords => totalWords - masteredWords;
  double get masteredProgress => totalWords > 0 ? masteredWords / totalWords : 0;
}

class LearnNotifier extends StateNotifier<LearnState> {
  final Ref _ref;

  LearnNotifier(this._ref) : super(const LearnState());

  String _dailyWordConfigKey() {
    final now = DateTime.now();
    return 'daily_word_index_${now.year}_${now.month}_${now.day}';
  }

  /// Pick a word from [nbId] at the given offset. Returns null if notebook is empty.
  Future<Word?> _pickFromNotebook(int nbId, int index) async {
    final wordRepo = _ref.read(wordRepoProvider);
    final words = await wordRepo.getByNotebook(nbId);
    if (words.isEmpty) return null;
    final now = DateTime.now();
    final seed = now.year * 400 + now.month * 40 + now.day;
    return words[(seed + index) % words.length];
  }

  /// Pick daily word from current notebook, falling back to other notebooks.
  Future<Word?> _pickDailyWord(int currentNbId, int index) async {
    final nbRepo = _ref.read(notebookRepoProvider);
    final notebooks = await nbRepo.getAll();

    Word? word = await _pickFromNotebook(currentNbId, index);
    if (word != null) return word;

    for (final nb in notebooks) {
      if (nb.id == currentNbId) continue;
      word = await _pickFromNotebook(nb.id!, index);
      if (word != null) return word;
    }
    return null;
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      final nbRepo = _ref.read(notebookRepoProvider);
      final wordRepo = _ref.read(wordRepoProvider);
      final reviewRepo = _ref.read(reviewRepoProvider);
      final configRepo = ConfigRepository();
      final notebooks = await nbRepo.getAll();
      final savedNotebookIdStr = await configRepo.get('active_notebook_id');
      final savedNotebookId = savedNotebookIdStr != null ? int.tryParse(savedNotebookIdStr) : null;
      // Validate saved ID still exists
      final validSavedId = savedNotebookId != null && notebooks.any((n) => n.id == savedNotebookId)
          ? savedNotebookId
          : null;
      final currentId = validSavedId ?? state.currentNotebookId ?? notebooks.firstOrNull?.id;
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
      final todayNewWords = totalWords == 0
          ? 0
          : (dailyLimit - learnedNew).clamp(0, dailyLimit).clamp(0, dbNewCount);
      final todayReviewBudget = (todayNewWords / 10).ceil();
      final todayReviewWords = totalWords == 0
          ? 0
          : (todayReviewBudget - learnedReview).clamp(0, todayReviewBudget).clamp(0, dbReviewCount);
      print('DEBUG todayNewWords=$todayNewWords todayReviewWords=$todayReviewWords dbNew=$dbNewCount dbReview=$dbReviewCount');

      final remaining = totalWords - masteredWords;
      final estimatedDays = dailyLimit > 0 ? (remaining / dailyLimit).ceil() : 0;

      // --- Daily word: only update on first load, date change, or current word deleted ---
      Word? dailyWord = state.dailyWord;
      int dailyWordIndex = state.dailyWordIndex;

      final storedIndexStr = await configRepo.get(_dailyWordConfigKey());
      final persistedIndex = storedIndexStr != null ? int.tryParse(storedIndexStr) ?? 0 : 0;

      // Date change detected (persisted index is for new day)
      final dateChanged = storedIndexStr == null && state.dailyWord != null;
      // Current word deleted
      final currentWordGone = state.dailyWord != null &&
          !await wordRepo.existsByText(state.dailyWord!.text);

      if (state.dailyWord == null || dateChanged || currentWordGone) {
        dailyWordIndex = dateChanged ? 0 : persistedIndex;
        dailyWord = await _pickDailyWord(currentNb.id!, dailyWordIndex);
        if (dailyWord != null) {
          await configRepo.set(_dailyWordConfigKey(), dailyWordIndex.toString());
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
        dailyWordIndex: dailyWordIndex,
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(loading: false, errorMessage: '加载失败，请检查数据库');
    }
  }

  Future<void> setCurrentNotebook(int id) async {
    state = state.copyWith(currentNotebookId: id);
    final configRepo = ConfigRepository();
    await configRepo.set('active_notebook_id', id.toString());
    load();
  }

  Future<void> setDailyLimit(int limit) async {
    final nb = state.currentNotebook;
    if (nb == null) return;
    final updated = nb.copyWith(dailyNewWordLimit: limit);
    await _ref.read(notebookRepoProvider).update(updated);
    load();
  }

  Future<void> nextDailyWord() async {
    final nb = state.currentNotebook;
    if (nb == null) return;

    final nextIndex = state.dailyWordIndex + 1;
    final nextWord = await _pickDailyWord(nb.id!, nextIndex);
    if (nextWord == null) return;

    final configRepo = ConfigRepository();
    await configRepo.set(_dailyWordConfigKey(), nextIndex.toString());

    state = state.copyWith(dailyWord: nextWord, dailyWordIndex: nextIndex);
  }
}
