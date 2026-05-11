import 'package:go_router/go_router.dart';
import '../../features/learn/learn_page.dart';
import '../../features/learn/study_page.dart';
import '../../features/wordbook/wordbook_page.dart';
import '../../features/wordbook/notebook_detail_page.dart';
import '../../features/wordbook/word_detail_page.dart';
import '../../features/archive/archive_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/capture/photo_capture_page.dart';
import '../../features/capture/capture_result_page.dart';
import '../../widgets/navigation_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/learn',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => NavigationShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/learn',
              builder: (context, state) => const LearnPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/wordbook',
              builder: (context, state) => const WordbookPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/archive',
              builder: (context, state) => const ArchivePage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/learn/study',
      builder: (context, state) => const StudyPage(),
    ),
    GoRoute(
      path: '/wordbook/:id',
      builder: (context, state) => NotebookDetailPage(id: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/word/:id',
      builder: (context, state) => WordDetailPage(id: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/capture/photo',
      builder: (context, state) => const PhotoCapturePage(),
    ),
    GoRoute(
      path: '/capture/result',
      builder: (context, state) => const CaptureResultPage(),
    ),
  ],
);
