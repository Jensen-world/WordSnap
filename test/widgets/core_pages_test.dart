import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordsnap/data/models/notebook.dart';
import 'package:wordsnap/data/models/word.dart';
import 'package:wordsnap/features/learn/learn_provider.dart';
import 'package:wordsnap/features/learn/learn_page.dart';
import 'package:wordsnap/features/wordbook/wordbook_provider.dart';
import 'package:wordsnap/features/archive/archive_provider.dart';
import 'package:wordsnap/features/archive/archive_page.dart';
import 'package:wordsnap/features/wordbook/wordbook_page.dart';

final now = DateTime(2026, 5, 10);

Notebook _notebook({int id = 1, String name = '拾词集', bool isDefault = true, int limit = 10}) =>
    Notebook(id: id, name: name, isDefault: isDefault, dailyNewWordLimit: limit, createdAt: now);

Word _word({int id = 1, int nb = 1, String text = 'test', bool isNew = true,
    int reviewCount = 0, bool isMastered = false}) =>
    Word(id: id, notebookId: nb, text: text, isNew: isNew, reviewCount: reviewCount,
        isMastered: isMastered, learnedAt: now, createdAt: now, updatedAt: now);

ProviderScope _wrap(List<Override> overrides, Widget child) {
  return ProviderScope(overrides: overrides, child: MaterialApp(home: child));
}

void main() {
  group('LearnPage', () {
    testWidgets('shows loading spinner when loading', (tester) async {
      await tester.pumpWidget(_wrap([
        learnStateProvider.overrideWith((ref) => _LoadingLearnNotifier(ref)),
      ], const LearnPage()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message on error state', (tester) async {
      final nb = _notebook();
      await tester.pumpWidget(_wrap([
        learnStateProvider.overrideWith((ref) => _FakeLearnNotifier(ref,
          LearnState(
            loading: false,
            errorMessage: '加载失败，请检查数据库',
            notebooks: [nb],
            currentNotebook: nb,
          ),
        )),
      ], const LearnPage()));

      expect(find.text('加载失败，请检查数据库'), findsOneWidget);
    });

    testWidgets('shows learning plan with today quota', (tester) async {
      final nb = _notebook(name: '拾词集');
      await tester.pumpWidget(_wrap([
        learnStateProvider.overrideWith((ref) => _FakeLearnNotifier(ref,
          LearnState(
            loading: false,
            notebooks: [nb],
            currentNotebook: nb,
            currentNotebookId: 1,
            newWords: 10,
            reviewWords: 1,
            dbNewWords: 3,
            dbReviewWords: 6,
            masteredWords: 3,
            totalWords: 12,
            dailyLimit: 10,
            estimatedDays: 1,
          ),
        )),
      ], const LearnPage()));

      expect(find.text('新学词'), findsOneWidget);
      expect(find.text('待复习'), findsOneWidget);
    });

    testWidgets('shows daily word card with word text', (tester) async {
      final nb = _notebook();
      final dailyWord = _word(text: 'serendipity', isNew: false, reviewCount: 5);
      await tester.pumpWidget(_wrap([
        learnStateProvider.overrideWith((ref) => _FakeLearnNotifier(ref,
          LearnState(
            loading: false,
            notebooks: [nb],
            currentNotebook: nb,
            currentNotebookId: 1,
            newWords: 5,
            reviewWords: 1,
            dailyLimit: 10,
            estimatedDays: 1,
            dailyWord: dailyWord,
          ),
        )),
      ], const LearnPage()));

      expect(find.text('serendipity'), findsOneWidget);
    });

    testWidgets('shows empty state when no words', (tester) async {
      final nb = _notebook();
      await tester.pumpWidget(_wrap([
        learnStateProvider.overrideWith((ref) => _FakeLearnNotifier(ref,
          LearnState(
            loading: false,
            notebooks: [nb],
            currentNotebook: nb,
            currentNotebookId: 1,
            newWords: 0,
            reviewWords: 0,
            dbNewWords: 0,
            dbReviewWords: 0,
            masteredWords: 0,
            totalWords: 0,
            dailyLimit: 10,
            estimatedDays: 0,
          ),
        )),
      ], const LearnPage()));

      expect(find.text('你的单词本中还没有记录单词。'), findsOneWidget);
      expect(find.text('开始学习'), findsOneWidget); // button still renders
    });
  });

  group('ArchivePage', () {
    testWidgets('shows archive stats correctly', (tester) async {
      await tester.pumpWidget(_wrap([
        archiveProvider.overrideWith((ref) async => ArchiveState(
          masteredCount: 42,
          totalCount: 100,
          reviewingCount: 50,
          notebookCount: 3,
          studyDays: 30,
          totalReviews: 520,
          firstStudyDate: DateTime(2026, 4, 10),
        )),
      ], const ArchivePage()));

      await tester.pumpAndSettle();

      expect(find.text('42'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('30 天'), findsOneWidget);
    });
  });

  group('WordbookPage', () {
    testWidgets('shows notebook cards with names', (tester) async {
      final notebooks = [
        _notebook(id: 1, name: '拾词集', isDefault: true),
        _notebook(id: 2, name: '日常英语', isDefault: false),
        _notebook(id: 3, name: '商务词汇', isDefault: false, limit: 20),
      ];

      await tester.pumpWidget(_wrap([
        notebooksProvider.overrideWith(() => _FakeNotebooksNotifier(notebooks)),
        notebookStatsProvider.overrideWith((ref, id) async {
          switch (id) {
            case 1: return const NotebookStats(newCount: 3, reviewCount: 6, masteredCount: 3, totalCount: 12);
            case 2: return const NotebookStats(newCount: 5, reviewCount: 2, masteredCount: 1, totalCount: 8);
            case 3: return const NotebookStats(newCount: 10, reviewCount: 15, masteredCount: 20, totalCount: 45);
            default: return const NotebookStats(newCount: 0, reviewCount: 0, masteredCount: 0, totalCount: 0);
          }
        }),
      ], const WordbookPage()));

      await tester.pumpAndSettle();

      expect(find.text('拾词集'), findsOneWidget);
      expect(find.text('日常英语'), findsOneWidget);
      expect(find.text('商务词汇'), findsOneWidget);
    });
  });
}

// --- Fake notifiers ---

class _LoadingLearnNotifier extends LearnNotifier {
  _LoadingLearnNotifier(super.ref);

  @override
  Future<void> load() async {}
}

class _FakeLearnNotifier extends LearnNotifier {
  _FakeLearnNotifier(super.ref, LearnState state) {
    this.state = state;
  }

  @override
  Future<void> load() async {}
}

class _FakeNotebooksNotifier extends NotebooksNotifier {
  final List<Notebook> _notebooks;

  _FakeNotebooksNotifier(this._notebooks);

  @override
  Future<List<Notebook>> build() async => _notebooks;
}
