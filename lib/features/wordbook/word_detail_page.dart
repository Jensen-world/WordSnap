import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../data/models/word.dart';
import '../../data/models/word_context.dart';
import 'wordbook_provider.dart';

class WordDetailPage extends ConsumerStatefulWidget {
  final int id;
  const WordDetailPage({super.key, required this.id});

  @override
  ConsumerState<WordDetailPage> createState() => _WordDetailPageState();
}

class _WordDetailPageState extends ConsumerState<WordDetailPage> {
  Word? _word;
  String _notebookName = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWord();
  }

  Future<void> _loadWord() async {
    try {
      final word = await ref.read(wordRepoProvider).getById(widget.id);
      if (word != null) {
        final notebooks = await ref.read(notebookRepoProvider).getAll();
        final nb = notebooks.where((n) => n.id == word.notebookId).firstOrNull;
        if (mounted) {
          setState(() {
            _word = word;
            _notebookName = nb?.name ?? '';
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddTagDialog() async {
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('添加标签', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入标签名...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消', style: TextStyle(color: Color(0xFF999999)))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('添加', style: TextStyle(color: AppColors.signalBlue))),
        ],
      ),
    );
    if (tag != null && tag.isNotEmpty && _word != null) {
      final updated = _word!.copyWith(tags: [..._word!.tags, tag]);
      await ref.read(wordRepoProvider).update(updated);
      await _loadWord();
    }
  }

  Future<void> _removeTag(String tag) async {
    if (_word == null) return;
    final updated = _word!.copyWith(tags: _word!.tags.where((t) => t != tag).toList());
    await ref.read(wordRepoProvider).update(updated);
    await _loadWord();
  }

  Future<int?> _showNotebookPicker() async {
    final notebooks = ref.read(notebooksProvider).value ?? [];
    final others = notebooks.where((n) => n.id != _word!.notebookId).toList();
    if (others.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('没有其他单词本')));
      }
      return null;
    }
    return showModalBottomSheet<int>(
      context: context,
      builder: (ctx) {
        final bottomPad = 24 + MediaQuery.of(ctx).padding.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: others.map((n) => ListTile(
              title: Text(n.name),
              onTap: () => Navigator.pop(ctx, n.id),
            )).toList(),
          ),
        );
      },
    );
  }

  Future<void> _moveWord() async {
    final targetId = await _showNotebookPicker();
    if (targetId == null || _word == null) return;
    final updated = _word!.copyWith(
      notebookId: targetId,
      isNew: true,
      reviewCount: 0,
      isMastered: false,
      learnedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await ref.read(wordRepoProvider).update(updated);
    ref.read(dataRefreshTrigger.notifier).state++;
    if (mounted) context.pop();
  }

  Future<void> _deleteWord() async {
    if (_word == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除单词'),
        content: Text('确定删除「${_word!.text}」吗？'),
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
      await ref.read(wordRepoProvider).delete(_word!.id!);
      ref.read(dataRefreshTrigger.notifier).state++;
      if (mounted) context.pop();
    }
  }

  Widget _buildSourceInfo(Word word) {
    final ctx = word.contexts.isNotEmpty ? word.contexts.first : null;
    final (icon, label) = _contextDisplay(ctx);
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF999999)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.inkBlack)),
        const SizedBox(width: 8),
        if (ctx != null)
          Text(
            '${ctx.timestamp.year}/${ctx.timestamp.month}/${ctx.timestamp.day}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
        if (_notebookName.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(_notebookName, style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
          ),
        ],
      ],
    );
  }

  (IconData, String) _contextDisplay(WordContext? ctx) {
    switch (ctx?.type) {
      case ContextType.photo: return (Icons.camera_alt_outlined, '拍照识别');
      case ContextType.clipboard: return (Icons.content_copy_outlined, '剪贴板');
      case ContextType.manual: return (Icons.edit_outlined, '手动输入');
      case ContextType.chat: return (Icons.chat_bubble_outline, 'WordChat');
      case ContextType.fileImport: return (Icons.upload_file_outlined, '文件导入');
      case ContextType.web: return (Icons.language, '网页');
      default: return (Icons.content_copy_outlined, '未知来源');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('单词详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_word == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('单词详情')),
        body: const Center(child: Text('未找到该单词')),
      );
    }

    final word = _word!;
    return Scaffold(
      backgroundColor: AppColors.canvasWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('单词详情'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            onPressed: () => context.push('/chat?word=${Uri.encodeComponent(word.text)}'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (action) {
              if (action == 'move') _moveWord();
              if (action == 'delete') _deleteWord();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'move', child: Text('移动到其他单词本')),
              PopupMenuItem(value: 'delete', child: Text('删除单词', style: TextStyle(color: Color(0xFFFF5252)))),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _WordHeader(
            text: word.text,
            phonetic: word.phonetic ?? '',
          ),
          const SizedBox(height: 20),
          _Section(
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
          _Section(
            title: '例句',
            child: word.examples.isEmpty
                ? const Text('暂无例句', style: TextStyle(fontSize: 13, color: Color(0xFF999999)))
                : Column(
                    children: word.examples.asMap().entries.map((e) {
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
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.inkBlack,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  if (word.exampleTranslation != null && word.exampleTranslation!.isNotEmpty) ...[
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
                            IconButton(
                              icon: const Icon(Icons.volume_up_outlined, size: 18, color: Color(0xFF999999)),
                              onPressed: () => ref.read(ttsServiceProvider).speak(e.value),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: '学习状态',
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: '录入时间',
                    value: '${word.createdAt.year}/${word.createdAt.month}/${word.createdAt.day}',
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: '状态',
                    value: word.isMastered
                        ? '已掌握'
                        : word.isNew
                            ? '新词'
                            : '复习中',
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: '复习次数',
                    value: '${word.reviewCount}/10',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: '标签',
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...word.tags.map((tag) => InputChip(
                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                  backgroundColor: const Color(0xFFF0F0F5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF999999)),
                  onDeleted: () => _removeTag(tag),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                )),
                ActionChip(
                  label: const Text('+ 添加', style: TextStyle(fontSize: 12, color: AppColors.signalBlue)),
                  onPressed: _showAddTagDialog,
                  backgroundColor: const Color(0xFFF0F0F5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: '录入来源',
            child: _buildSourceInfo(word),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _WordHeader extends ConsumerWidget {
  final String text;
  final String phonetic;

  const _WordHeader({
    required this.text,
    required this.phonetic,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.inkBlack),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F5),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('美', style: TextStyle(fontSize: 12, color: AppColors.inkBlack)),
              const SizedBox(width: 8),
              Text(phonetic, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => ref.read(ttsServiceProvider).speak(text),
                child: const Icon(Icons.volume_up_outlined, size: 16, color: Color(0xFF999999)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

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
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF999999),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

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
