import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notebook.dart';
import '../../data/models/word.dart';
import '../wordbook/wordbook_provider.dart';
import '../../data/services/dictionary_result.dart';
import '../../data/services/dictionary_service.dart';

final dictionaryServiceProvider = Provider((ref) => DictionaryService());

final captureStateProvider = StateNotifierProvider<CaptureNotifier, CaptureState>((ref) {
  return CaptureNotifier(ref);
});

class CaptureState {
  final String input;
  final bool searching;
  final DictionaryResult? result;
  final String? errorMessage;
  final List<Notebook> notebooks;
  final int? selectedNotebookId;

  const CaptureState({
    this.input = '',
    this.searching = false,
    this.result,
    this.errorMessage,
    this.notebooks = const [],
    this.selectedNotebookId,
  });

  CaptureState copyWith({
    String? input,
    bool? searching,
    DictionaryResult? result,
    String? errorMessage,
    List<Notebook>? notebooks,
    int? selectedNotebookId,
    bool clearResult = false,
    bool clearError = false,
  }) => CaptureState(
    input: input ?? this.input,
    searching: searching ?? this.searching,
    result: clearResult ? null : (result ?? this.result),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    notebooks: notebooks ?? this.notebooks,
    selectedNotebookId: selectedNotebookId ?? this.selectedNotebookId,
  );
}

class CaptureNotifier extends StateNotifier<CaptureState> {
  final Ref _ref;

  CaptureNotifier(this._ref) : super(const CaptureState());

  Future<void> loadNotebooks() async {
    final repo = _ref.read(notebookRepoProvider);
    final notebooks = await repo.getAll();
    state = state.copyWith(
      notebooks: notebooks,
      selectedNotebookId: notebooks.isNotEmpty ? notebooks.first.id : null,
    );
  }

  void setInput(String input) {
    state = state.copyWith(input: input, clearResult: true, clearError: true);
  }

  void reset() {
    state = const CaptureState();
  }

  Future<void> lookup() async {
    final word = state.input.trim();
    if (word.isEmpty) return;
    state = state.copyWith(searching: true, clearError: true);
    final service = _ref.read(dictionaryServiceProvider);
    final result = await service.lookup(word);
    state = state.copyWith(
      searching: false,
      result: result,
      errorMessage: result == null ? '查不到该单词，请检查拼写' : null,
      clearError: result != null,
    );
  }

  void setNotebook(int id) {
    state = state.copyWith(selectedNotebookId: id);
  }

  Future<Word> save() async {
    final result = state.result;
    if (result == null || state.selectedNotebookId == null) {
      throw StateError('Missing result or notebook');
    }
    final now = DateTime.now();
    final defs = result.primaryDefinitions;
    final word = Word(
      notebookId: state.selectedNotebookId!,
      text: result.word,
      phonetic: result.phonetic,
      partOfSpeech: result.meanings.isNotEmpty ? result.meanings.first.partOfSpeech : null,
      definitions: defs,
      exampleSentence: result.exampleSentence,
      exampleTranslation: result.exampleTranslation,
      examples: result.exampleSentence != null ? [result.exampleSentence!] : [],
      tags: result.tag != null ? result.tag!.split(' ') : [],
      learnedAt: now,
      createdAt: now,
      updatedAt: now,
    );
    final repo = _ref.read(wordRepoProvider);
    return repo.insert(word);
  }
}
