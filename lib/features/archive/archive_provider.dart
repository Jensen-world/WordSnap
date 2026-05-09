import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../wordbook/wordbook_provider.dart';

final archiveProvider = FutureProvider<ArchiveState>((ref) async {
  final wordRepo = ref.read(wordRepoProvider);
  final nbRepo = ref.read(notebookRepoProvider);
  final reviewRepo = ref.read(reviewRepoProvider);

  final masteredCount = await wordRepo.getCount(isMastered: true);
  final totalCount = await wordRepo.getCount();
  final reviewingCount = await wordRepo.getCount(isNew: false, isMastered: false);
  final notebooks = await nbRepo.getAll();
  final recentSessions = await reviewRepo.getRecent(365);

  final studyDays = recentSessions.length;
  final totalReviews = recentSessions.fold<int>(0, (sum, s) => sum + s.wordsReviewed);
  final firstStudyDate = recentSessions.isNotEmpty
      ? recentSessions.last.date
      : DateTime.now();

  return ArchiveState(
    masteredCount: masteredCount,
    totalCount: totalCount,
    reviewingCount: reviewingCount,
    notebookCount: notebooks.length,
    studyDays: studyDays,
    totalReviews: totalReviews,
    firstStudyDate: firstStudyDate,
  );
});

class ArchiveState {
  final int masteredCount;
  final int totalCount;
  final int reviewingCount;
  final int notebookCount;
  final int studyDays;
  final int totalReviews;
  final DateTime firstStudyDate;

  const ArchiveState({
    this.masteredCount = 0,
    this.totalCount = 0,
    this.reviewingCount = 0,
    this.notebookCount = 0,
    this.studyDays = 0,
    this.totalReviews = 0,
    required this.firstStudyDate,
  });
}
