import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import 'learn_provider.dart';
import 'learn_settings_sheet.dart';
import '../../data/models/word.dart';
import '../wordbook/wordbook_provider.dart';

class LearnPage extends ConsumerStatefulWidget {
  const LearnPage({super.key});

  @override
  ConsumerState<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends ConsumerState<LearnPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(learnStateProvider.notifier).load());
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const LearnSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dataRefreshTrigger, (_, __) {
      ref.read(learnStateProvider.notifier).load();
    });
    final state = ref.watch(learnStateProvider);

    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.errorMessage!, style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.read(learnStateProvider.notifier).load(),
              child: const Text('重试', style: TextStyle(color: AppColors.signalBlue)),
            ),
          ],
        ),
      );
    }

    final current = state.currentNotebook;
    if (current == null) {
      return const Center(child: Text('暂无单词本', style: TextStyle(color: Color(0xFF999999))));
    }

    final bottomPad = 16 + 5 + MediaQuery.of(context).padding.bottom;

    return RefreshIndicator(
      onRefresh: () => ref.read(learnStateProvider.notifier).load(),
      child: ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
      children: [
        _NotebookCard(
          notebookId: current.id,
          name: current.name,
          newCount: state.dbNewWords,
          reviewCount: state.dbReviewWords,
          masteredCount: state.masteredWords,
          totalCount: state.totalWords,
          onEdit: _showSettings,
          progress: state.masteredProgress,
          masteredPercent: (state.masteredProgress * 100).toInt(),
          masteredFraction: '${state.masteredWords} / ${state.totalWords}',
        ),
        const SizedBox(height: 10),
        _StudyPlanCard(
          newCount: state.newWords,
          reviewCount: state.reviewWords,
          dailyLimit: state.dailyLimit,
          estimatedDays: state.estimatedDays,
          onStart: () => context.push('/learn/study'),
        ),
        const SizedBox(height: 10),
        _DailyWordCard(notebookName: current.name, dailyWord: state.dailyWord),
      ],
      ),
    );
  }
}

class _NotebookCard extends StatelessWidget {
  final int? notebookId;
  final String name;
  final int newCount;
  final int reviewCount;
  final int masteredCount;
  final int totalCount;
  final VoidCallback onEdit;
  final double progress;
  final int masteredPercent;
  final String masteredFraction;

  const _NotebookCard({
    required this.notebookId,
    required this.name,
    required this.newCount,
    required this.reviewCount,
    required this.masteredCount,
    required this.totalCount,
    required this.onEdit,
    required this.progress,
    required this.masteredPercent,
    required this.masteredFraction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '正在学习的单词本',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF999999), letterSpacing: 0.6),
              ),
              Text(
                'Active Notebook',
                style: TextStyle(fontSize: 10, color: Color(0xFFBBBBBB)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => context.push('/wordbook/$notebookId'),
                child: Container(
                  width: 64,
                  height: 84,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF0F0F5), Color(0xFFE8E8F0)],
                    ),
                    border: Border.fromBorderSide(BorderSide(color: Color(0xFFE2E2EA))),
                  ),
                  child: const Icon(Icons.menu_book_rounded, size: 32, color: AppColors.signalBlue),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/wordbook/$notebookId'),
                      child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.inkBlack)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('$newCount 新词', style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.lavender)),
                        const SizedBox(width: 12),
                        Text('$reviewCount 待复习', style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.signalBlue)),
                        const SizedBox(width: 12),
                        Text('$masteredCount 掌握', style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.mint)),
                        const SizedBox(width: 12),
                        Text('$totalCount 总计', style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: Color(0xFF999999))),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E2EA)),
                  ),
                  child: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF999999)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFF0F0F5),
              color: AppColors.mint,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('已掌握 $masteredPercent%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: AppColors.mint)),
              Text(masteredFraction, style: const TextStyle(fontSize: 9, color: Color(0xFFBBBBBB))),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudyPlanCard extends StatelessWidget {
  final int newCount;
  final int reviewCount;
  final int dailyLimit;
  final int estimatedDays;
  final VoidCallback onStart;

  const _StudyPlanCard({
    required this.newCount,
    required this.reviewCount,
    required this.dailyLimit,
    required this.estimatedDays,
    required this.onStart,
  });

  static const _months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${_months[now.month]} ${now.day}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '今日学习计划',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF999999), letterSpacing: 0.6),
              ),
              Text(
                "Today's Plan · $dateStr",
                style: const TextStyle(fontSize: 10, color: Color(0xFFBBBBBB)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _PlanNumberCard(number: newCount, label: '新学词', color: AppColors.signalBlue)),
              const SizedBox(width: 12),
              Expanded(child: _PlanNumberCard(number: reviewCount, label: '待复习', color: AppColors.amberFlash)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _PlanIndicator(value: '$dailyLimit', label: '每日新学'),
              Container(width: 1, height: 24, color: const Color(0xFFF0F0F5)),
              _PlanIndicator(value: '$estimatedDays', label: '预计天数', valueColor: AppColors.lavender),
              Container(width: 1, height: 24, color: const Color(0xFFF0F0F5)),
              const _PlanIndicator(value: '10:1', label: '新复比'),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onStart,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.signalBlue,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                '开始学习',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanNumberCard extends StatelessWidget {
  final int number;
  final String label;
  final Color color;

  const _PlanNumberCard({required this.number, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text(
            '$number',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500, fontFamily: 'JetBrains Mono', color: color, height: 1),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
        ],
      ),
    );
  }
}

class _PlanIndicator extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _PlanIndicator({required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, fontFamily: 'JetBrains Mono', color: valueColor ?? AppColors.inkBlack),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
      ],
    );
  }
}

class _DailyWordCard extends ConsumerWidget {
  final String notebookName;
  final Word? dailyWord;

  const _DailyWordCard({required this.notebookName, this.dailyWord});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final word = dailyWord;

    if (word == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '每日一词',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF999999), letterSpacing: 0.6),
            ),
            const SizedBox(height: 40),
            const Center(
              child: Icon(Icons.menu_book_rounded, size: 48, color: Color(0xFFE8E8F0)),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                '你的单词本中还没有记录单词。',
                style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    final notebooks = ref.watch(learnStateProvider.select((s) => s.notebooks));
    final sourceName = notebooks.where((n) => n.id == word.notebookId).firstOrNull?.name ?? notebookName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '每日一词',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF999999), letterSpacing: 0.6),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => ref.read(learnStateProvider.notifier).nextDailyWord(),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 12, color: Color(0xFF999999)),
                        SizedBox(width: 2),
                        Text('换一个', style: TextStyle(fontSize: 10, color: Color(0xFF999999))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('来自 $sourceName', style: const TextStyle(fontSize: 10, color: Color(0xFFBBBBBB))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    if (word.id != null) context.push('/word/${word.id}');
                  },
                  child: Text(
                    word.text,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.inkBlack),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => context.push('/chat?word=${Uri.encodeComponent(word.text)}'),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEF0FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.signalBlue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F5),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('美', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkBlack)),
                    const SizedBox(width: 6),
                    Text(word.phonetic ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => ref.read(ttsServiceProvider).speak(word.text),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEF0FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.volume_up_outlined, size: 16, color: AppColors.signalBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (word.definitions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 13, color: AppColors.inkBlack, height: 1.5),
                  children: [
                    if (word.partOfSpeech != null && word.partOfSpeech!.isNotEmpty)
                      TextSpan(
                        text: '${word.partOfSpeech} ',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.signalBlue),
                      ),
                    TextSpan(text: word.definitions.first),
                  ],
                ),
              ),
            ),
          if (word.exampleSentence != null && word.exampleSentence!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF0F0F5))),
              ),
              width: double.infinity,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '"${word.exampleSentence}"',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF666666), fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => ref.read(ttsServiceProvider).speak(word.exampleSentence!),
                        child: const Icon(Icons.volume_up_outlined, size: 16, color: Color(0xFF999999)),
                      ),
                    ],
                  ),
                  if (word.exampleTranslation != null && word.exampleTranslation!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      word.exampleTranslation!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
