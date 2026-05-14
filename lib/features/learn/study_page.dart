import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../data/models/word.dart';
import 'study_provider.dart';
import 'learn_provider.dart';
import 'learn_settings_sheet.dart';
import '../wordbook/wordbook_provider.dart';

class StudyPage extends ConsumerStatefulWidget {
  const StudyPage({super.key});

  @override
  ConsumerState<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends ConsumerState<StudyPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final learn = ref.read(learnStateProvider);
      final notebookId = learn.currentNotebookId ?? 1;
      final dailyLimit = learn.dailyLimit;
      ref.read(studyProvider.notifier).startSession(notebookId, dailyLimit);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studyProvider);
    final learn = ref.watch(learnStateProvider);
    final word = state.currentWord;

    if (state.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('学习中')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.finished) {
      if (state.queue.isEmpty) {
        if (learn.dailyLimit == 0 && learn.totalWords > 0) {
          return Scaffold(
            appBar: AppBar(title: const Text('学习中')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book_rounded, size: 64, color: Color(0xFFE8E8F0)),
                  const SizedBox(height: 16),
                  const Text(
                    '暂无单词需要学习',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.inkBlack),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '请先设置每日学习计划',
                    style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () { ref.read(dataRefreshTrigger.notifier).state++; ref.read(learnStateProvider.notifier).load(); context.pop(); },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E2EA)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                        child: const Text('返回', style: TextStyle(color: Color(0xFF999999))),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useRootNavigator: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (_) => const LearnSettingsSheet(),
                          ).then((_) {
                            final updated = ref.read(learnStateProvider);
                            if (updated.dailyLimit > 0) {
                              ref.read(studyProvider.notifier).startSession(
                                updated.currentNotebookId ?? 1,
                                updated.dailyLimit,
                              );
                            }
                          });
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.signalBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                        child: const Text('设置'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('学习中')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book_rounded, size: 64, color: Color(0xFFE8E8F0)),
                const SizedBox(height: 16),
                const Text(
                  '暂无单词需要学习',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.inkBlack),
                ),
                const SizedBox(height: 8),
                const Text(
                  '请先在单词本中添加单词',
                  style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () { ref.read(dataRefreshTrigger.notifier).state++; ref.read(learnStateProvider.notifier).load(); context.pop(); },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.signalBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  child: const Text('返回'),
                ),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(title: const Text('学习完成')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 64, color: AppColors.mint),
              const SizedBox(height: 16),
              const Text(
                '本次学习完成',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.inkBlack),
              ),
              const SizedBox(height: 8),
              Text(
                '答对 ${state.correctCount} 题 · 答错 ${state.incorrectCount} 题',
                style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () { ref.read(dataRefreshTrigger.notifier).state++; ref.read(learnStateProvider.notifier).load(); context.pop(); },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.signalBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvasWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('拾词集 · 学习中'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () { ref.read(dataRefreshTrigger.notifier).state++; ref.read(learnStateProvider.notifier).load(); context.pop(); }),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              '${state.progress}/${state.queue.length}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (word != null)
                Expanded(
                  child: state.showingDefinition
                      ? _DefinitionView(word: word)
                      : _CardView(word: word),
                ),
              if (word != null) ...[
                if (!state.showingDefinition) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            ref.read(ttsServiceProvider).stop();
                            await ref.read(studyProvider.notifier).markIncorrect();
                            ref.read(studyProvider.notifier).showDefinition();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFFE2E2EA)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          ),
                          child: const Text('不认识', style: TextStyle(fontSize: 16, color: AppColors.inkBlack)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            ref.read(ttsServiceProvider).stop();
                            await ref.read(studyProvider.notifier).markCorrect();
                            ref.read(studyProvider.notifier).showDefinition();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.signalBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          ),
                          child: const Text('认识 ✓', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
                if (state.showingDefinition) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () {
                      ref.read(ttsServiceProvider).stop();
                      ref.read(studyProvider.notifier).nextWord();
                    },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.signalBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: const Text('下一词 →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('✓ ${state.correctCount}', style: const TextStyle(fontSize: 13, color: AppColors.mint)),
                    const SizedBox(width: 16),
                    Text('✗ ${state.incorrectCount}', style: const TextStyle(fontSize: 13, color: Color(0xFFFF5252))),
                  ],
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardView extends ConsumerStatefulWidget {
  final Word word;

  const _CardView({required this.word});

  @override
  ConsumerState<_CardView> createState() => _CardViewState();
}

class _CardViewState extends ConsumerState<_CardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ttsServiceProvider).speak(widget.word.text);
    });
  }

  @override
  void didUpdateWidget(_CardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word.id != widget.word.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(ttsServiceProvider).speak(widget.word.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.word;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: word.isNew ? AppColors.signalBlue.withAlpha(25) : const Color(0xFFFFA940).withAlpha(30),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              word.isNew ? '新词' : '复习',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: word.isNew ? AppColors.signalBlue : AppColors.amberFlash,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            word.text,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.inkBlack),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F5),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('美', style: TextStyle(fontSize: 12, color: AppColors.inkBlack)),
                const SizedBox(width: 8),
                Text(
                  word.phonetic ?? '',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => ref.read(ttsServiceProvider).speak(word.text),
                  child: const Icon(Icons.volume_up_outlined, size: 18, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DefinitionView extends ConsumerStatefulWidget {
  final Word word;

  const _DefinitionView({required this.word});

  @override
  ConsumerState<_DefinitionView> createState() => _DefinitionViewState();
}

class _DefinitionViewState extends ConsumerState<_DefinitionView> {
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _speakAll();
  }

  Future<void> _speakAll() async {
    _speaking = true;
    final tts = ref.read(ttsServiceProvider);
    tts.stop();
    await Future.delayed(const Duration(milliseconds: 120));
    if (!_speaking || !mounted) return;

    await tts.speak(widget.word.text);
    if (!_speaking || !mounted) return;

    for (final ex in widget.word.examples) {
      await tts.speak(ex);
      if (!_speaking || !mounted) return;
    }
    _speaking = false;
  }

  @override
  void dispose() {
    _speaking = false;
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.word;
    return ListView(
      children: [
        Center(
          child: Text(
            word.text,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.inkBlack),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F5),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('美', style: TextStyle(fontSize: 12, color: AppColors.inkBlack)),
                const SizedBox(width: 8),
                Text(
                  word.phonetic ?? '',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => ref.read(ttsServiceProvider).speak(word.text),
                  child: const Icon(Icons.volume_up_outlined, size: 18, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _DefSection(
          title: '释义',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (word.partOfSpeech != null && word.partOfSpeech!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    word.partOfSpeech!,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.signalBlue),
                  ),
                ),
              ...word.definitions.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  word.definitions.length > 1 ? '${e.key + 1}. ${e.value}' : e.value,
                  style: const TextStyle(fontSize: 13, color: AppColors.inkBlack, height: 1.5),
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DefSection(
          title: '例句',
          child: Column(
            children: word.examples.asMap().entries.map((e) {
              final isFirst = e.key == 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.value,
                            style: const TextStyle(fontSize: 13, color: AppColors.inkBlack, fontStyle: FontStyle.italic),
                          ),
                          if (isFirst && word.exampleTranslation != null && word.exampleTranslation!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              word.exampleTranslation!,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => ref.read(ttsServiceProvider).speak(e.value),
                      child: const Icon(Icons.volume_up_outlined, size: 18, color: Color(0xFF999999)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DefSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DefSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
