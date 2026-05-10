import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wordsnap/app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('App launch and navigation', () {
    testWidgets('app launches and shows LearnPage', (tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // The LearnPage should show the notebook card and study plan
      expect(find.text('正在学习的单词本'), findsOneWidget);
      expect(find.text('今日学习计划'), findsOneWidget);
      expect(find.text('开始学习'), findsOneWidget);
    });

    testWidgets('bottom tab bar switches between pages', (tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Wordbook (middle tab)
      await tester.tap(find.text('单词本'));
      await tester.pumpAndSettle();
      expect(find.text('新建单词本'), findsWidgets);

      // Navigate to Archive (right tab)
      await tester.tap(find.text('档案卡'));
      await tester.pumpAndSettle();
      expect(find.text('已掌握'), findsOneWidget);
      expect(find.text('成就'), findsOneWidget);

      // Navigate back to Learn (left tab)
      await tester.tap(find.text('记单词'));
      await tester.pumpAndSettle();
      expect(find.text('正在学习的单词本'), findsOneWidget);
    });
  });

  group('Wordbook CRUD', () {
    testWidgets('create and see a new notebook', (tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Go to Wordbook tab
      await tester.tap(find.text('单词本'));
      await tester.pumpAndSettle();

      // Tap "新建单词本" button (the last item in the list)
      await tester.tap(find.text('新建单词本').last);
      await tester.pumpAndSettle();

      // The CreateNotebookSheet should appear with a text field
      expect(find.byType(TextField), findsOneWidget);

      // Type a name
      await tester.enterText(find.byType(TextField), 'E2E Test NB');
      await tester.pumpAndSettle();

      // Tap create button
      await tester.tap(find.text('创建'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // The new notebook should appear in the list
      expect(find.text('E2E Test NB'), findsOneWidget);
    });
  });

  group('Learning flow', () {
    testWidgets('navigates to study page from LearnPage', (tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap "开始学习" on LearnPage
      await tester.tap(find.text('开始学习'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Study page shows either cards or empty state
      final onStudyPage = find.text('暂无单词需要学习').evaluate().isNotEmpty ||
          find.text('认识').evaluate().isNotEmpty ||
          find.text('不认识').evaluate().isNotEmpty;
      expect(onStudyPage, isTrue);
    });
  });
}
