import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../data/models/notebook.dart';
import '../../data/models/word.dart';
import '../../data/models/word_context.dart';
import '../../data/services/dictionary_result.dart';
import '../wordbook/wordbook_provider.dart';
import 'capture_provider.dart';

class ShareReceiptSheet extends ConsumerStatefulWidget {
  final String sharedText;

  const ShareReceiptSheet({super.key, required this.sharedText});

  @override
  ConsumerState<ShareReceiptSheet> createState() => _ShareReceiptSheetState();
}

class _ShareReceiptSheetState extends ConsumerState<ShareReceiptSheet> {
  DictionaryResult? _result;
  bool _searching = true;
  String? _error;
  List<Notebook> _notebooks = [];
  int? _selectedNotebookId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadNotebooks();
    _lookup();
  }

  Future<void> _loadNotebooks() async {
    final repo = ref.read(notebookRepoProvider);
    final notebooks = await repo.getAll();
    if (mounted) {
      setState(() {
        _notebooks = notebooks;
        _selectedNotebookId = notebooks.isNotEmpty ? notebooks.first.id : null;
      });
    }
  }

  Future<void> _lookup() async {
    final service = ref.read(dictionaryServiceProvider);
    final result = await service.lookup(widget.sharedText.trim());
    if (mounted) {
      setState(() {
        _searching = false;
        _result = result;
        _error = result == null ? '查不到该单词' : null;
      });
    }
  }

  Future<void> _save() async {
    if (_result == null || _selectedNotebookId == null) return;
    setState(() => _saving = true);
    try {
      final notebookId = _selectedNotebookId!;
      final repo = ref.read(wordRepoProvider);

      // Check duplicate in same notebook
      final exists = await repo.existsByTextInNotebook(_result!.word, notebookId);
      if (exists) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('「${_result!.word}」已在本单词本中')),
          );
        }
        return;
      }

      final notebookName = _notebooks
          .where((n) => n.id == notebookId)
          .firstOrNull
          ?.name ?? '';

      final now = DateTime.now();
      final r = _result!;
      final defs = r.primaryDefinitions;
      final word = Word(
        notebookId: notebookId,
        text: r.word,
        phonetic: r.phonetic,
        partOfSpeech: r.meanings.isNotEmpty ? r.meanings.first.partOfSpeech : null,
        definitions: defs,
        exampleSentence: r.exampleSentence,
        exampleTranslation: r.exampleTranslation,
        examples: r.exampleSentence != null ? [r.exampleSentence!] : [],
        tags: r.tag != null ? r.tag!.split(' ') : [],
        contexts: [WordContext(type: ContextType.clipboard, source: notebookName, timestamp: now)],
        learnedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      await repo.insert(word);
      ref.read(dataRefreshTrigger.notifier).state++;
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.sharedText.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: const BoxDecoration(color: Color(0xFFDDDDDD), borderRadius: BorderRadius.all(Radius.circular(2))),
            ),
          ),
          const SizedBox(height: 20),
          const Text('已收到单词', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.inkBlack), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          const Text('来自其他应用', style: TextStyle(fontSize: 12, color: Color(0xFF999999)), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(word, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.inkBlack), textAlign: TextAlign.center),
          if (_searching)
            const Padding(padding: EdgeInsets.only(top: 24), child: Center(child: CircularProgressIndicator())),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_error!, style: const TextStyle(fontSize: 13, color: Color(0xFFFF5252)), textAlign: TextAlign.center),
            ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            _ResultCard(result: _result!),
            const SizedBox(height: 16),
            const Text('存入', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
            const SizedBox(height: 8),
            _NotebookSelector(
              notebooks: _notebooks,
              selectedId: _selectedNotebookId,
              onSelected: (id) => setState(() => _selectedNotebookId = id),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E2EA)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('忽略', style: TextStyle(color: Color(0xFF999999))),
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
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('收录', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
  final DictionaryResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(result.word, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.inkBlack)),
          const SizedBox(height: 6),
          if (result.phonetic != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFF0F0F5), borderRadius: BorderRadius.circular(100)),
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
        ],
      ),
    );
  }
}

class _NotebookSelector extends StatelessWidget {
  final List<Notebook> notebooks;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  const _NotebookSelector({required this.notebooks, required this.selectedId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book_rounded, size: 16, color: AppColors.signalBlue),
            const SizedBox(width: 8),
            Text(_selectedName(), style: const TextStyle(fontSize: 14, color: AppColors.inkBlack)),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  String _selectedName() {
    if (selectedId == null) return '选择单词本';
    return notebooks.where((n) => n.id == selectedId).firstOrNull?.name ?? '选择单词本';
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
              title: Text(n.name, style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.signalBlue : AppColors.inkBlack,
              )),
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
