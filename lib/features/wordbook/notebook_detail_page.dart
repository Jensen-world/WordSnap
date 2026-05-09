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
  bool _selectionMode = false;
  final Set<int> _selectedWordIds = {};

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
    switch (action) {
      case 'select':
        setState(() {
          _selectionMode = true;
          _selectedWordIds.clear();
        });
      case 'clear':
        _showConfirmDialog(
          title: '清空单词本',
          content: '将删除本单词本中的所有单词，不可恢复。',
          onConfirm: () async {
            final repo = ref.read(wordRepoProvider);
            for (final w in _words) {
              await repo.delete(w.id!);
            }
            _loadWords();
          },
        );
      case 'deleteNb':
        _showConfirmDialog(
          title: '删除单词本',
          content: '删除后所有单词也将被删除，不可恢复。',
          onConfirm: () async {
            await ref.read(notebooksProvider.notifier).delete(widget.id);
            if (mounted) context.pop();
          },
          isDanger: true,
        );
    }
  }

  void _showConfirmDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
    bool isDanger = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(isDanger ? '删除' : '确认', style: TextStyle(color: isDanger ? const Color(0xFFFF5252) : AppColors.signalBlue)),
          ),
        ],
      ),
    );
  }

  Future<int?> _showNotebookPicker() async {
    final notebooks = ref.read(notebooksProvider).value ?? [];
    final others = notebooks.where((n) => n.id != widget.id).toList();
    if (others.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('没有其他单词本')));
      }
      return null;
    }
    return showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: others.map((n) => ListTile(
            title: Text(n.name),
            onTap: () => Navigator.pop(ctx, n.id),
          )).toList(),
        ),
      ),
    );
  }

  Future<void> _moveWord(Word word) async {
    final targetId = await _showNotebookPicker();
    if (targetId == null) return;
    final updated = word.copyWith(
      notebookId: targetId,
      isNew: true,
      reviewCount: 0,
      isMastered: false,
      learnedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await ref.read(wordRepoProvider).update(updated);
    _loadWords();
  }

  Future<void> _batchMove() async {
    final targetId = await _showNotebookPicker();
    if (targetId == null) return;
    final now = DateTime.now();
    final repo = ref.read(wordRepoProvider);
    for (final id in _selectedWordIds) {
      final word = _words.firstWhere((w) => w.id == id);
      final updated = word.copyWith(
        notebookId: targetId,
        isNew: true,
        reviewCount: 0,
        isMastered: false,
        learnedAt: now,
        updatedAt: now,
      );
      await repo.update(updated);
    }
    setState(() {
      _selectionMode = false;
      _selectedWordIds.clear();
    });
    _loadWords();
  }

  Future<void> _deleteWord(Word word) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除单词'),
        content: Text('确定删除「${word.text}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(wordRepoProvider).delete(word.id!);
      _loadWords();
    }
  }

  void _toggleWordSelection(int id) {
    setState(() {
      if (_selectedWordIds.contains(id)) {
        _selectedWordIds.remove(id);
      } else {
        _selectedWordIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedWordIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定删除选中的 $count 个单词吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final repo = ref.read(wordRepoProvider);
      for (final id in _selectedWordIds) {
        await repo.delete(id);
      }
      setState(() {
        _selectionMode = false;
        _selectedWordIds.clear();
      });
      _loadWords();
    }
  }

  String _notebookName() {
    final notebooks = ref.read(notebooksProvider).value ?? [];
    return notebooks.where((n) => n.id == widget.id).map((n) => n.name).firstOrNull ?? '';
  }

  bool get _isDefault {
    final notebooks = ref.read(notebooksProvider).value ?? [];
    return notebooks.any((n) => n.id == widget.id && n.isDefault);
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
        title: Text(_selectionMode ? '已选 ${_selectedWordIds.length} 项' : _notebookName()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_selectionMode) {
              setState(() { _selectionMode = false; _selectedWordIds.clear(); });
            } else {
              GoRouter.of(context).go('/wordbook');
            }
          },
        ),
        actions: _selectionMode
            ? [
                TextButton(
                  onPressed: () => setState(() { _selectionMode = false; _selectedWordIds.clear(); }),
                  child: const Text('取消', style: TextStyle(color: AppColors.inkBlack)),
                ),
              ]
            : [
          PopupMenuButton<String>(
            onSelected: (v) => _onManageAction(v),
            itemBuilder: (_) {
              final items = <PopupMenuEntry<String>>[
                const PopupMenuItem(value: 'select', child: Text('批量管理')),
                const PopupMenuItem(value: 'clear', child: Text('清空单词本')),
              ];
              if (!_isDefault) {
                items.add(const PopupMenuItem(value: 'deleteNb', child: Text('删除单词本', style: TextStyle(color: Color(0xFFFF5252)))));
              }
              return items;
            },
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
          if (!_selectionMode)
            _FilterTabs(current: _filter, onChanged: _onFilterChanged),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async => _loadWords(),
                    child: _buildWordList(context),
                  ),
          ),
          if (_selectionMode)
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E2EA))),
              ),
              child: Row(
                children: [
                  Text('已选 ${_selectedWordIds.length} 项', style: const TextStyle(fontSize: 14, color: AppColors.inkBlack)),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: _selectedWordIds.isEmpty ? null : _batchMove,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E2EA)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: const Text('移动', style: TextStyle(fontSize: 14, color: AppColors.inkBlack)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _selectedWordIds.isEmpty ? null : _deleteSelected,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5252),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: const Text('删除', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ],
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
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final date = grouped.keys.elementAt(index);
        final words = grouped[date]!;
        return _DateGroup(
          date: date,
          words: words,
          selectionMode: _selectionMode,
          selectedIds: _selectedWordIds,
          onTap: (word) => _selectionMode ? _toggleWordSelection(word.id!) : context.push('/word/${word.id}'),
          onToggleSelection: (id) => _toggleWordSelection(id),
          onMoveWord: (word) => _moveWord(word),
          onDeleteWord: (word) => _deleteWord(word),
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
  final bool selectionMode;
  final Set<int> selectedIds;
  final ValueChanged<Word> onTap;
  final ValueChanged<int> onToggleSelection;
  final ValueChanged<Word> onMoveWord;
  final ValueChanged<Word> onDeleteWord;

  const _DateGroup({
    required this.date,
    required this.words,
    required this.selectionMode,
    required this.selectedIds,
    required this.onTap,
    required this.onToggleSelection,
    required this.onMoveWord,
    required this.onDeleteWord,
  });

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
              final isSelected = selectedIds.contains(word.id);
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
                      if (selectionMode) ...[
                        GestureDetector(
                          onTap: () => onToggleSelection(word.id!),
                          child: Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? AppColors.signalBlue : Colors.white,
                              border: Border.all(color: isSelected ? AppColors.signalBlue : const Color(0xFFDDDDDD), width: 2),
                            ),
                            child: isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                          ),
                        ),
                      ],
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
                      if (selectionMode)
                        const SizedBox.shrink()
                      else
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz, size: 16, color: Color(0xFF999999)),
                          padding: EdgeInsets.zero,
                          onSelected: (action) {
                            if (action == 'move') onMoveWord(word);
                            if (action == 'delete') onDeleteWord(word);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'move', child: Text('移动')),
                            PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Color(0xFFFF5252)))),
                          ],
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
