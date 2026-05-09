import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notebook.dart';
import '../../data/models/word.dart';
import '../../data/services/dictionary_result.dart';
import '../../data/services/dictionary_service.dart';
import '../../data/services/ocr_service.dart';
import '../wordbook/wordbook_provider.dart';

final photoCaptureProvider = StateNotifierProvider<PhotoCaptureNotifier, PhotoCaptureState>((ref) {
  return PhotoCaptureNotifier(ref);
});

enum PhotoStep { initial, processing, ready, lookingUp, result, saving, done }

class PhotoCaptureState {
  final PhotoStep step;
  final String? imagePath;
  final String fullText;
  final List<String> words;
  final String? selectedWord;
  final DictionaryResult? lookupResult;
  final String? errorMessage;
  final List<Notebook> notebooks;
  final int? selectedNotebookId;

  const PhotoCaptureState({
    this.step = PhotoStep.initial,
    this.imagePath,
    this.fullText = '',
    this.words = const [],
    this.selectedWord,
    this.lookupResult,
    this.errorMessage,
    this.notebooks = const [],
    this.selectedNotebookId,
  });

  PhotoCaptureState copyWith({
    PhotoStep? step,
    String? imagePath,
    String? fullText,
    List<String>? words,
    String? selectedWord,
    DictionaryResult? lookupResult,
    String? errorMessage,
    List<Notebook>? notebooks,
    int? selectedNotebookId,
    bool clearSelectedWord = false,
    bool clearLookupResult = false,
    bool clearError = false,
  }) =>
      PhotoCaptureState(
        step: step ?? this.step,
        imagePath: imagePath ?? this.imagePath,
        fullText: fullText ?? this.fullText,
        words: words ?? this.words,
        selectedWord: clearSelectedWord ? null : (selectedWord ?? this.selectedWord),
        lookupResult: clearLookupResult ? null : (lookupResult ?? this.lookupResult),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        notebooks: notebooks ?? this.notebooks,
        selectedNotebookId: selectedNotebookId ?? this.selectedNotebookId,
      );
}

class PhotoCaptureNotifier extends StateNotifier<PhotoCaptureState> {
  final Ref _ref;
  final _ocr = OcrService();
  final _dict = DictionaryService();

  PhotoCaptureNotifier(this._ref) : super(const PhotoCaptureState());

  Future<void> processImage(String path) async {
    state = state.copyWith(step: PhotoStep.processing, imagePath: path);
    try {
      final result = await _ocr.processImage(path);
      state = state.copyWith(
        step: PhotoStep.ready,
        fullText: result.fullText,
        words: result.words,
      );
    } catch (_) {
      state = state.copyWith(
        step: PhotoStep.ready,
        fullText: '',
        words: [],
        errorMessage: '文字识别失败，请重试或确认图片清晰',
      );
    }
  }

  Future<void> loadNotebooks() async {
    final repo = _ref.read(notebookRepoProvider);
    final notebooks = await repo.getAll();
    state = state.copyWith(
      notebooks: notebooks,
      selectedNotebookId: notebooks.isNotEmpty ? notebooks.first.id : null,
    );
  }

  Future<void> lookup(String word) async {
    state = state.copyWith(step: PhotoStep.lookingUp, selectedWord: word, clearError: true);
    final result = await _dict.lookup(word);
    if (result != null) {
      state = state.copyWith(step: PhotoStep.result, lookupResult: result);
    } else {
      state = state.copyWith(
        step: PhotoStep.ready,
        errorMessage: '查不到 $word，请检查拼写',
        clearSelectedWord: true,
      );
    }
  }

  void setNotebook(int id) {
    state = state.copyWith(selectedNotebookId: id);
  }

  void backToWords() {
    state = state.copyWith(step: PhotoStep.ready, clearSelectedWord: true, clearLookupResult: true);
  }

  Future<Word> save() async {
    final result = state.lookupResult;
    if (result == null || state.selectedNotebookId == null) {
      throw StateError('Missing result or notebook');
    }
    state = state.copyWith(step: PhotoStep.saving);
    final now = DateTime.now();
    final allDefs = <String>[];
    if (result.translation != null) allDefs.add(result.translation!);
    allDefs.addAll(result.meanings.expand((m) => m.definitions.map((d) => d.definition)));
    final word = Word(
      notebookId: state.selectedNotebookId!,
      text: result.word,
      phonetic: result.phonetic,
      partOfSpeech: result.meanings.isNotEmpty ? result.meanings.first.partOfSpeech : null,
      definitions: allDefs,
      examples: result.meanings.expand((m) => m.definitions.map((d) => d.example).whereType<String>()).toList(),
      tags: result.tag != null ? result.tag!.split(' ') : [],
      learnedAt: now,
      createdAt: now,
      updatedAt: now,
    );
    final repo = _ref.read(wordRepoProvider);
    final saved = await repo.insert(word);
    state = state.copyWith(step: PhotoStep.done);
    return saved;
  }

  void retake() {
    state = const PhotoCaptureState();
  }

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }
}
