import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../data/models/word.dart';
import 'wordbook_provider.dart';

class NotebookDetailPage extends ConsumerStatefulWidget {
  final int id;
  const NotebookDetailPage({super.key, required this.id});

  @override
  ConsumerState<NotebookDetailPage> createState() => _NotebookDetailPageState();
}

enum WordFilter { all, newWords, mastered }

class _NotebookDetailPageState extends ConsumerState<NotebookDetailPage> {
  WordFilter _filter = WordFilter.all;
  List<Word> _words = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    setState(() => _loading = true);
    final repo = ref.read(wordRepoProvider);
    List<Word> words;
    switch (_filter) {
      case WordFilter.all:
        words = await repo.getByNotebook(widget.id);
      case WordFilter.newWords:
        words = await repo.getByNotebookAndStatus(widget.id, isNew: true);
      case WordFilter.mastered:
        words = await repo.getByNotebookAndStatus(widget.id, isMastered: true);
    }
    if (mounted) {
      setState(() {
        _words = words;
        _loading = false;
      });
    }
  }

  void _onFilterChanged(WordFilter filter) {
    setState(() => _filter = filter);
    _loadWords();
  }

  void _onManageAction(String action) {
    if (action == 'delete') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('删除单词本'),
          content: const Text('删除后所有单词也将被删除，不可恢复。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(notebooksProvider.notifier).delete(widget.id);
                if (mounted) context.pop();
              },
              child: const Text('删除', style: TextStyle(color: Color(0xFFFF5252))),
            ),
          ],
        ),
      );
    }
  }

  String _formatDateGroup(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year) {
      return '${date.month}月${date.day}日';
    }
    return '${date.year}/${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('拾词集'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).go('/wordbook'),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => _onManageAction(v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('删除单词本', style: TextStyle(color: Color(0xFFFF5252)))),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('管理', style: TextStyle(fontSize: 14, color: AppColors.inkBlack)),
                  Icon(Icons.arrow_drop_down, size: 18, color: AppColors.inkBlack),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterTabs(current: _filter, onChanged: _onFilterChanged),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async => _loadWords(),
                    child: _buildWordList(context),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordList(BuildContext context) {
    if (_words.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(child: Text('暂无单词', style: TextStyle(color: Color(0xFF999999)))),
        ],
      );
    }

    final grouped = <String, List<Word>>{};
    for (final word in _words) {
      final key = _formatDateGroup(word.learnedAt);
      grouped.putIfAbsent(key, () => []).add(word);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final date = grouped.keys.elementAt(index);
        final words = grouped[date]!;
        return _DateGroup(
          date: date,
          words: words,
          onTap: (word) => context.push('/word/${word.id}'),
        );
      },
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final WordFilter current;
  final ValueChanged<WordFilter> onChanged;

  const _FilterTabs({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E2EA))),
      ),
      child: Row(
        children: [
          _Tab(label: '全部', active: current == WordFilter.all, onTap: () => onChanged(WordFilter.all)),
          const SizedBox(width: 6),
          _Tab(label: '新词', active: current == WordFilter.newWords, onTap: () => onChanged(WordFilter.newWords)),
          const SizedBox(width: 6),
          _Tab(label: '掌握', active: current == WordFilter.mastered, onTap: () => onChanged(WordFilter.mastered)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.signalBlue : const Color(0xFFF0F0F5),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : const Color(0xFF999999),
          ),
        ),
      ),
    );
  }
}

class _DateGroup extends StatelessWidget {
  final String date;
  final List<Word> words;
  final ValueChanged<Word> onTap;

  const _DateGroup({required this.date, required this.words, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, top: 6, bottom: 6),
          child: Text(
            date,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF999999)),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E2EA)),
          ),
          child: Column(
            children: words.map((word) {
              return GestureDetector(
                onTap: () => onTap(word),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: word != words.last
                        ? const Border(bottom: BorderSide(color: Color(0xFFE2E2EA)))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 15, color: AppColors.inkBlack),
                            children: [
                              TextSpan(text: word.text, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const TextSpan(text: ' '),
                              TextSpan(
                                text: _posLabel(word.partOfSpeech),
                                style: const TextStyle(color: Color(0xFF999999)),
                              ),
                              TextSpan(
                                text: _firstDef(word.definitions),
                                style: const TextStyle(color: Color(0xFF666666)),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, size: 16, color: Color(0xFF999999)),
                        onPressed: () {},
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  static String _posLabel(String? pos) {
    if (pos == null || pos.isEmpty) return '';
    return '$pos. ';
  }

  static String _firstDef(List<String> defs) {
    return defs.isNotEmpty ? defs.first : '';
  }
}
