import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import 'archive_provider.dart';

class ArchivePage extends ConsumerWidget {
  const ArchivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archiveAsync = ref.watch(archiveProvider);

    return archiveAsync.when(
      data: (state) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(archiveProvider),
        child: _buildContent(context, state),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('加载失败', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.invalidate(archiveProvider),
              child: const Text('重试', style: TextStyle(color: AppColors.signalBlue)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic state) {
    final bottomPad = 16 + 30 + MediaQuery.of(context).padding.bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
      children: [
        _HeroCard(masteredCount: state.masteredCount, firstStudyDate: state.firstStudyDate, studyDays: state.studyDays, totalReviews: state.totalReviews),
        const SizedBox(height: 14),
        _QuickStats(total: state.totalCount, reviewing: state.reviewingCount, notebooks: state.notebookCount),
        const SizedBox(height: 20),
        const Text(
          '成就',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inkBlack),
        ),
        const SizedBox(height: 12),
        _AchievementGrid(masteredCount: state.masteredCount, studyDays: state.studyDays, notebookCount: state.notebookCount),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int masteredCount;
  final DateTime firstStudyDate;
  final int studyDays;
  final int totalReviews;

  const _HeroCard({
    required this.masteredCount,
    required this.firstStudyDate,
    required this.studyDays,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E2EA)),
      ),
      child: Column(
        children: [
          const Text('已掌握', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
          const SizedBox(height: 8),
          Text(
            '$masteredCount',
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w700,
              fontFamily: 'JetBrains Mono',
              color: AppColors.mint,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text('个单词', style: TextStyle(fontSize: 16, color: AppColors.inkBlack)),
          const SizedBox(height: 20),
          Container(height: 1, color: const Color(0xFFE2E2EA)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HeroStat(label: '首次学习', value: '${firstStudyDate.year}/${firstStudyDate.month}/${firstStudyDate.day}'),
              _HeroStat(label: '学习天数', value: '$studyDays 天'),
              _HeroStat(label: '复习总次数', value: '$totalReviews'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.inkBlack)),
      ],
    );
  }
}

class _QuickStats extends StatelessWidget {
  final int total;
  final int reviewing;
  final int notebooks;

  const _QuickStats({required this.total, required this.reviewing, required this.notebooks});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatBox(number: '$total', label: '词汇总量', color: AppColors.inkBlack)),
        const SizedBox(width: 10),
        Expanded(child: _StatBox(number: '$reviewing', label: '复习中', color: AppColors.amberFlash)),
        const SizedBox(width: 10),
        Expanded(child: _StatBox(number: '$notebooks', label: '单词本', color: AppColors.lavender)),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String number;
  final String label;
  final Color color;

  const _StatBox({required this.number, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E2EA)),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'JetBrains Mono', color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
        ],
      ),
    );
  }
}

class _AchievementGrid extends StatelessWidget {
  final int masteredCount;
  final int studyDays;
  final int notebookCount;

  const _AchievementGrid({
    required this.masteredCount,
    required this.studyDays,
    required this.notebookCount,
  });

  @override
  Widget build(BuildContext context) {
    final achievements = [
      _Ach('掌握 10 词', masteredCount >= 10, masteredCount, 10),
      _Ach('掌握 100 词', masteredCount >= 100, masteredCount, 100),
      _Ach('掌握 1000 词', masteredCount >= 1000, masteredCount, 1000),
      _Ach('掌握 5000 词', masteredCount >= 5000, masteredCount, 5000),
      _Ach('连续学习 7 天', studyDays >= 7, studyDays, 7),
      _Ach('连续学习 30 天', studyDays >= 30, studyDays, 30),
      _Ach('连续学习 90 天', studyDays >= 90, studyDays, 90),
      _Ach('连续学习 180 天', studyDays >= 180, studyDays, 180),
      _Ach('创建 3 个单词本', notebookCount >= 3, notebookCount, 3),
      _Ach('创建 10 个单词本', notebookCount >= 10, notebookCount, 10),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: achievements.map((a) => _AchievementChip(label: a.label, unlocked: a.unlocked, current: a.current, target: a.target)).toList(),
    );
  }
}

class _Ach {
  final String label;
  final bool unlocked;
  final int current;
  final int target;
  _Ach(this.label, this.unlocked, this.current, this.target);
}

class _AchievementChip extends StatelessWidget {
  final String label;
  final bool unlocked;
  final int current;
  final int target;

  const _AchievementChip({
    required this.label,
    required this.unlocked,
    required this.current,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.mint.withAlpha(20) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked ? AppColors.mint : const Color(0xFFE2E2EA),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            unlocked ? '✓' : '○',
            style: TextStyle(
              fontSize: 14,
              color: unlocked ? AppColors.mint : const Color(0xFFCCCCCC),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: unlocked ? AppColors.mint : const Color(0xFF999999),
            ),
          ),
          if (!unlocked) ...[
            const SizedBox(width: 6),
            Text(
              '$current/$target',
              style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
            ),
          ],
        ],
      ),
    );
  }
}
