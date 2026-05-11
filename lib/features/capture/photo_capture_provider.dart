import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import '../../data/models/notebook.dart';
import '../../data/models/word.dart';
import '../../data/services/dictionary_result.dart';
import '../../data/services/dictionary_service.dart';
import '../../data/services/ocr_service.dart';
import '../wordbook/wordbook_provider.dart';

final photoCaptureProvider = StateNotifierProvider<PhotoCaptureNotifier, PhotoCaptureState>((ref) {
  return PhotoCaptureNotifier(ref);
});

enum PhotoStep { initial, processing, selecting, lookingUp, result, saving, done }

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
    state = state.copyWith(step: PhotoStep.selecting, imagePath: path, clearError: true);
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
        step: PhotoStep.selecting,
        errorMessage: '查不到 $word，请检查拼写',
        clearSelectedWord: true,
      );
    }
  }

  void setNotebook(int id) {
    state = state.copyWith(selectedNotebookId: id);
  }

  Future<void> confirmSelection({
    required double displayWidth,
    required double displayHeight,
    required double cropX,
    required double cropY,
    required double cropW,
    required double cropH,
  }) async {
    final path = state.imagePath;
    if (path == null) return;

    // Get original image dimensions
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      state = state.copyWith(errorMessage: '无法读取照片');
      return;
    }
    final imageWidth = decoded.width;
    final imageHeight = decoded.height;

    state = state.copyWith(step: PhotoStep.lookingUp, clearError: true);

    final word = await _ocr.processCroppedRegion(
      path,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      displayWidth: displayWidth,
      displayHeight: displayHeight,
      cropX: cropX,
      cropY: cropY,
      cropW: cropW,
      cropH: cropH,
    );

    if (word != null) {
      await lookup(word);
    } else {
      state = state.copyWith(
        step: PhotoStep.selecting,
        errorMessage: '未识别到英文单词，请重试',
      );
    }
  }

  void backToWords() {
    state = state.copyWith(step: PhotoStep.selecting, clearSelectedWord: true, clearLookupResult: true);
  }

  Future<Word> save() async {
    final result = state.lookupResult;
    if (result == null || state.selectedNotebookId == null) {
      throw StateError('Missing result or notebook');
    }
    state = state.copyWith(step: PhotoStep.saving);
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
