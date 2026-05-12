import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/colors.dart';
import '../../data/models/word.dart';
import '../../data/models/notebook.dart';
import '../../data/services/file_io.dart'
  if (dart.library.js_interop) '../../data/services/file_web.dart';
import '../learn/learn_provider.dart';
import 'wordbook_provider.dart';

class ImportWordlistSheet extends ConsumerStatefulWidget {
  const ImportWordlistSheet({super.key});

  @override
  ConsumerState<ImportWordlistSheet> createState() => _ImportWordlistSheetState();
}

class _ParsedEntry {
  final String word;
  final String definition;

  const _ParsedEntry(this.word, [this.definition = '']);
}

class _ImportWordlistSheetState extends ConsumerState<ImportWordlistSheet> {
  String? _fileName;
  List<_ParsedEntry> _entries = [];
  late TextEditingController _nameCtrl;
  bool _importing = false;
  int _importedCount = 0;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    Future.microtask(_pickFile);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'csv'],
    );
    if (result == null || result.files.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final file = result.files.first;
    final name = file.name;
    final content = await readImportFile(file);

    _parseContent(name, content);
  }

  void _parseContent(String fileName, String content) {
    final lines = content.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    final ext = fileName.toLowerCase();
    final entries = <_ParsedEntry>[];

    if (ext.endsWith('.csv')) {
      for (final line in lines) {
        final parts = line.split(',').map((p) => p.trim()).toList();
        if (parts.isNotEmpty && parts[0].isNotEmpty) {
          entries.add(_ParsedEntry(parts[0], parts.length > 1 ? parts[1] : ''));
        }
      }
    } else {
      for (final line in lines) {
        final word = line.trim();
        if (word.isNotEmpty) {
          entries.add(_ParsedEntry(word));
        }
      }
    }

    if (entries.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final baseName = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
    setState(() {
      _fileName = fileName;
      _entries = entries;
      _nameCtrl.text = baseName;
    });
  }

  Future<void> _confirm() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _entries.isEmpty) return;

    setState(() => _importing = true);

    final notebookRepo = ref.read(notebookRepoProvider);
    final wordRepo = ref.read(wordRepoProvider);
    final notebook = Notebook(name: name, createdAt: DateTime.now());
    final created = await notebookRepo.insert(notebook);
    final now = DateTime.now();

    final words = _entries.map((e) => Word(
      notebookId: created.id!,
      text: e.word,
      definitions: e.definition.isNotEmpty ? [e.definition] : [],
      learnedAt: now,
      createdAt: now,
      updatedAt: now,
    )).toList();

    final count = await wordRepo.insertBatch(words);
    ref.read(dataRefreshTrigger.notifier).state++;
    ref.read(learnStateProvider.notifier).load();

    if (mounted) {
      setState(() {
        _importing = false;
        _importedCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom + 24;

    if (_fileName == null) {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomPad + 40),
        child: const Center(child: CircularProgressIndicator(color: AppColors.signalBlue)),
      );
    }

    if (_importedCount > 0) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 40, 20, bottomPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            const Text('导入完成', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.inkBlack)),
            const SizedBox(height: 8),
            Text('已导入 $_importedCount 个单词', style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.signalBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: const Text('完成'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFDDDDDD),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('导入单词表', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.inkBlack), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            '$_fileName · ${_entries.length} 个单词',
            style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E2EA)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F5)),
                itemBuilder: (_, i) {
                  final e = _entries[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.word,
                            style: const TextStyle(fontSize: 14, color: AppColors.inkBlack),
                          ),
                        ),
                        if (e.definition.isNotEmpty)
                          Text(e.definition, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('单词本名称', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: '输入单词本名称',
              hintStyle: TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
            ),
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _importing ? null : _confirm,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.signalBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: _importing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('确认导入', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
