import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../data/models/notebook.dart';
import '../wordbook/wordbook_provider.dart';
import '../learn/learn_provider.dart';
import 'capture_provider.dart';

class CaptureResultPage extends ConsumerStatefulWidget {
  const CaptureResultPage({super.key});

  @override
  ConsumerState<CaptureResultPage> createState() => _CaptureResultPageState();
}

class _CaptureResultPageState extends ConsumerState<CaptureResultPage> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(captureStateProvider).input;
    Future.microtask(() => ref.read(captureStateProvider.notifier).loadNotebooks());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _requery() {
    final word = _controller.text.trim();
    if (word.isEmpty) return;
    ref.read(captureStateProvider.notifier).setInput(word);
    ref.read(captureStateProvider.notifier).lookup();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(captureStateProvider.notifier).save();
      ref.read(dataRefreshTrigger.notifier).state++;
      ref.read(learnStateProvider.notifier).load();
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(captureStateProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('查询结果'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _requery(),
                    decoration: const InputDecoration(
                      hintText: '请输入或粘贴你想记录的单词',
                      hintStyle: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0xFFE2E2EA)),
                      ),
                    ),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _requery,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.signalBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.search, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (state.searching)
            const Center(child: CircularProgressIndicator()),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(fontSize: 13, color: Color(0xFFFF5252)),
                textAlign: TextAlign.center,
              ),
            ),
          if (state.result != null) ...[
            _ResultCard(result: state.result!),
            const SizedBox(height: 16),
            const Text(
              '存入',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 8),
            _NotebookSelector(
              notebooks: state.notebooks,
              selectedId: state.selectedNotebookId,
              onSelected: (id) => ref.read(captureStateProvider.notifier).setNotebook(id),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('取消', style: TextStyle(color: Color(0xFF999999))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.signalBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('确认添加', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final dynamic result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E2EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            result.word,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.inkBlack),
          ),
          const SizedBox(height: 6),
          if (result.phonetic != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F5),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('美', style: TextStyle(fontSize: 11, color: AppColors.inkBlack)),
                  const SizedBox(width: 6),
                  Text(result.phonetic!, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => ProviderScope.containerOf(context).read(ttsServiceProvider).speak(result.word),
                    child: const Icon(Icons.volume_up_outlined, size: 14, color: Color(0xFF999999)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          if (result.primaryDefinition.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                result.primaryDefinition,
                style: const TextStyle(fontSize: 14, color: AppColors.inkBlack),
                textAlign: TextAlign.center,
              ),
            ),
          if (result.exampleSentence != null && result.exampleSentence!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF0F0F5))),
              ),
              width: double.infinity,
              child: Text(
                '"${result.exampleSentence}"',
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666), fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
            if (result.exampleTranslation != null && result.exampleTranslation!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  result.exampleTranslation!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _NotebookSelector extends StatelessWidget {
  final List<Notebook> notebooks;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  const _NotebookSelector({
    required this.notebooks,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E2EA)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book_rounded, size: 16, color: AppColors.signalBlue),
            const SizedBox(width: 8),
            Text(
              _selectedName(),
              style: const TextStyle(fontSize: 14, color: AppColors.inkBlack),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  String _selectedName() {
    if (selectedId == null) return '选择单词本';
    for (final n in notebooks) {
      if (n.id == selectedId) return n.name;
    }
    return '选择单词本';
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: notebooks.map((n) {
            final isSelected = n.id == selectedId;
            return ListTile(
              title: Text(
                n.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.signalBlue : AppColors.inkBlack,
                ),
              ),
              leading: isSelected ? const Icon(Icons.check, size: 18, color: AppColors.signalBlue) : null,
              onTap: () {
                onSelected(n.id!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
