import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notebook.dart';
import '../../data/repositories/notebook_repository.dart'
  if (dart.library.js_interop) '../../data/repositories/notebook_repository_web.dart';
import '../../data/repositories/word_repository.dart'
  if (dart.library.js_interop) '../../data/repositories/word_repository_web.dart';
import '../../data/repositories/review_repository.dart'
  if (dart.library.js_interop) '../../data/repositories/review_repository_web.dart';
import '../../data/services/tts_service.dart';

final notebookRepoProvider = Provider((ref) => NotebookRepository());
final wordRepoProvider = Provider((ref) => WordRepository());
final reviewRepoProvider = Provider((ref) => ReviewRepository());

final notebooksProvider = AsyncNotifierProvider<NotebooksNotifier, List<Notebook>>(NotebooksNotifier.new);

class NotebookStats {
  final int newCount;
  final int reviewCount;
  final int masteredCount;
  final int totalCount;

  const NotebookStats({
    required this.newCount,
    required this.reviewCount,
    required this.masteredCount,
    required this.totalCount,
  });
}

class NotebooksNotifier extends AsyncNotifier<List<Notebook>> {
  @override
  Future<List<Notebook>> build() async {
    final repo = ref.read(notebookRepoProvider);
    return repo.getAll();
  }

  Future<Notebook> create(String name) async {
    final repo = ref.read(notebookRepoProvider);
    final notebook = Notebook(name: name, createdAt: DateTime.now());
    final created = await repo.insert(notebook);
    ref.invalidateSelf();
    return created;
  }

  Future<void> edit(Notebook notebook) async {
    final repo = ref.read(notebookRepoProvider);
    await repo.update(notebook);
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    final repo = ref.read(notebookRepoProvider);
    await repo.delete(id);
    ref.invalidateSelf();
  }
}

final notebookStatsProvider = FutureProvider.family<NotebookStats, int>((ref, notebookId) async {
  final wordRepo = ref.read(wordRepoProvider);
  final newCount = await wordRepo.getCount(notebookId: notebookId, isNew: true);
  final masteredCount = await wordRepo.getCount(notebookId: notebookId, isMastered: true);
  final totalCount = await wordRepo.getCount(notebookId: notebookId);
  return NotebookStats(
    newCount: newCount,
    reviewCount: totalCount - newCount - masteredCount,
    masteredCount: masteredCount,
    totalCount: totalCount,
  );
});

final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());
