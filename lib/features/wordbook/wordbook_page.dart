import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../data/models/notebook.dart';
import 'wordbook_provider.dart';
import 'create_notebook_sheet.dart';

class WordbookPage extends ConsumerWidget {
  const WordbookPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notebooksAsync = ref.watch(notebooksProvider);

    return notebooksAsync.when(
      data: (notebooks) => _buildList(context, ref, notebooks),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('加载失败', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
            SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.invalidate(notebooksProvider),
              child: Text('重试', style: TextStyle(color: AppColors.signalBlue)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<Notebook> notebooks) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(notebooksProvider),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 20 + MediaQuery.of(context).padding.bottom),
        itemCount: notebooks.length + 1,
        itemBuilder: (context, i) {
          if (i == notebooks.length) {
            return _AddButton(onTap: () => _showCreateSheet(context, ref));
          }
          return _NotebookCard(
            notebook: notebooks[i],
            onTap: () => context.push('/wordbook/${notebooks[i].id}'),
            onEdit: () => _showEditSheet(context, ref, notebooks[i]),
          );
        },
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => const CreateNotebookSheet(),
    ).then((name) {
      if (name != null && name.isNotEmpty) {
        ref.read(notebooksProvider.notifier).create(name);
      }
    });
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Notebook notebook) {
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => CreateNotebookSheet(initialName: notebook.name),
    ).then((name) {
      if (name != null && name.isNotEmpty && name != notebook.name) {
        ref.read(notebooksProvider.notifier).edit(notebook.copyWith(name: name));
      }
    });
  }
}

class _NotebookCard extends ConsumerWidget {
  final Notebook notebook;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _NotebookCard({
    required this.notebook,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(notebookStatsProvider(notebook.id!));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFF0F0F5)),
              ),
              child: const Icon(Icons.menu_book_rounded, size: 22, color: AppColors.inkBlack),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        notebook.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.inkBlack),
                      ),
                      if (notebook.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('默认', style: TextStyle(fontSize: 10, color: Color(0xFF999999))),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  statsAsync.when(
                    data: (stats) => Row(
                      children: [
                        Text('${stats.newCount} 新词', style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.lavender)),
                        const SizedBox(width: 10),
                        Text('${stats.reviewCount} 待复习', style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.signalBlue)),
                        const SizedBox(width: 10),
                        Text('${stats.masteredCount} 掌握', style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.mint)),
                      ],
                    ),
                    loading: () => const Text('...', style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
                    error: (e, s) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF999999)),
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))],
        ),
        child: const Center(
          child: Text(
            '+ 新建单词本',
            style: TextStyle(fontSize: 14, color: AppColors.signalBlue, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
