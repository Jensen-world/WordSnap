import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../data/models/notebook.dart';
import 'learn_provider.dart';

class LearnSettingsSheet extends ConsumerStatefulWidget {
  const LearnSettingsSheet({super.key});

  @override
  ConsumerState<LearnSettingsSheet> createState() => _LearnSettingsSheetState();
}

class _LearnSettingsSheetState extends ConsumerState<LearnSettingsSheet> {
  bool _expanded = false;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(learnStateProvider.notifier).load());
  }

  List<Notebook> get _filteredNotebooks {
    final state = ref.read(learnStateProvider);
    if (_searchText.isEmpty) return state.notebooks;
    return state.notebooks.where((n) => n.name.contains(_searchText)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learnStateProvider);
    final current = state.currentNotebook;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '学习设置',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.inkBlack),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          const Text(
            '当前单词本',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E2EA)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, size: 16, color: AppColors.signalBlue),
                  const SizedBox(width: 10),
                  Text(
                    current?.name ?? '选择单词本',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.inkBlack),
                  ),
                  const Spacer(),
                  Icon(_expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down, size: 18, color: const Color(0xFF999999)),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E2EA)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchText = v),
                      decoration: const InputDecoration(
                        hintText: '搜索单词本...',
                        prefixIcon: Icon(Icons.search, size: 16, color: Color(0xFF999999)),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  ..._filteredNotebooks.map((nb) {
                    final selected = nb.id == current?.id;
                    return GestureDetector(
                      onTap: () {
                        ref.read(learnStateProvider.notifier).setCurrentNotebook(nb.id!);
                        setState(() => _expanded = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.signalBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.menu_book_rounded, size: 16, color: selected ? Colors.white : AppColors.signalBlue),
                            const SizedBox(width: 8),
                            Text(
                              nb.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: selected ? Colors.white : AppColors.inkBlack,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '词',
                              style: TextStyle(
                                fontSize: 10,
                                color: selected ? Colors.white.withAlpha(150) : const Color(0xFF999999),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            '每日新词上限',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('新词用完自动切纯复习', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                ),
                _CounterButton(
                  icon: '−',
                  onTap: () {
                    if (state.dailyLimit > 1) {
                      ref.read(learnStateProvider.notifier).setDailyLimit(state.dailyLimit - 1);
                    }
                  },
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${state.dailyLimit}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.inkBlack),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 10),
                _CounterButton(
                  icon: '+',
                  onTap: () => ref.read(learnStateProvider.notifier).setDailyLimit(state.dailyLimit + 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  '剩余 ${state.remainingNewWords} 个新词',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
                const Spacer(),
                Text(
                  '预计 ${state.estimatedDays} 天 学完',
                  style: const TextStyle(fontSize: 12, color: AppColors.lavender, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.signalBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: const Text('保存', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;

  const _CounterButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E2EA)),
        ),
        alignment: Alignment.center,
        child: Text(icon, style: const TextStyle(fontSize: 18, color: AppColors.inkBlack)),
      ),
    );
  }
}
