import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/word.dart';
import '../../data/models/review_session.dart';
import '../../data/services/review_service.dart';
import '../wordbook/wordbook_provider.dart';

final reviewServiceProvider = Provider((ref) => ReviewService(ref.read(wordRepoProvider)));

final studyProvider = StateNotifierProvider<StudyNotifier, StudyState>((ref) {
  return StudyNotifier(ref);
});

class StudyState {
  final List<Word> queue;
  final int currentIndex;
  final bool showingDefinition;
  final int correctCount;
  final int incorrectCount;
  final bool loading;
  final bool finished;

  const StudyState({
    this.queue = const [],
    this.currentIndex = 0,
    this.showingDefinition = false,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.loading = true,
    this.finished = false,
  });

  Word? get currentWord => currentIndex < queue.length ? queue[currentIndex] : null;
  int get progress => queue.isEmpty ? 0 : currentIndex + 1;

  StudyState copyWith({
    List<Word>? queue,
    int? currentIndex,
    bool? showingDefinition,
    int? correctCount,
    int? incorrectCount,
    bool? loading,
    bool? finished,
  }) => StudyState(
    queue: queue ?? this.queue,
    currentIndex: currentIndex ?? this.currentIndex,
    showingDefinition: showingDefinition ?? this.showingDefinition,
    correctCount: correctCount ?? this.correctCount,
    incorrectCount: incorrectCount ?? this.incorrectCount,
    loading: loading ?? this.loading,
    finished: finished ?? this.finished,
  );
}

class StudyNotifier extends StateNotifier<StudyState> {
  final Ref _ref;
  ReviewSession? _todaySession;

  StudyNotifier(this._ref) : super(const StudyState());

  Future<void> startSession(int notebookId, int dailyLimit) async {
    state = state.copyWith(loading: true);
    final reviewRepo = _ref.read(reviewRepoProvider);
    _todaySession = await reviewRepo.getOrCreateToday();
    final service = _ref.read(reviewServiceProvider);
    final queue = await service.getTodayQueue(notebookId, dailyLimit);
    state = state.copyWith(
      queue: queue,
      currentIndex: 0,
      showingDefinition: false,
      correctCount: 0,
      incorrectCount: 0,
      loading: false,
      finished: queue.isEmpty,
    );
  }

  void showDefinition() {
    state = state.copyWith(showingDefinition: true);
  }

  Future<void> markCorrect() async {
    final word = state.currentWord;
    if (word == null) return;
    final service = _ref.read(reviewServiceProvider);
    final reviewRepo = _ref.read(reviewRepoProvider);
    if (word.isNew) {
      await service.markNewCorrect(word);
      _todaySession = _todaySession!.copyWith(newWordsLearned: _todaySession!.newWordsLearned + 1);
    } else {
      await service.markCorrect(word);
      _todaySession = _todaySession!.copyWith(reviewWordsCorrect: _todaySession!.reviewWordsCorrect + 1);
    }
    await reviewRepo.update(_todaySession!);
    state = state.copyWith(correctCount: state.correctCount + 1);
  }

  Future<void> markIncorrect() async {
    final word = state.currentWord;
    if (word == null) return;
    final service = _ref.read(reviewServiceProvider);
    final reviewRepo = _ref.read(reviewRepoProvider);
    await service.markIncorrect(word);
    if (word.isNew) {
      _todaySession = _todaySession!.copyWith(newWordsLearned: _todaySession!.newWordsLearned + 1);
    } else {
      _todaySession = _todaySession!.copyWith(reviewWordsWrong: _todaySession!.reviewWordsWrong + 1);
    }
    await reviewRepo.update(_todaySession!);
    state = state.copyWith(incorrectCount: state.incorrectCount + 1);
  }

  Future<void> nextWord() async {
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.queue.length) {
      state = state.copyWith(finished: true);
    } else {
      state = state.copyWith(currentIndex: nextIndex, showingDefinition: false);
    }
  }
}
