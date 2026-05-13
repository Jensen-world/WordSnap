import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/colors.dart';
import '../../data/models/word.dart';
import '../../data/models/notebook.dart';
import '../../data/models/word_context.dart';
import '../../data/services/dictionary_service.dart';
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
      final wordRe = RegExp(r'[a-zA-Z]+');
      for (final line in lines) {
        final match = wordRe.firstMatch(line);
        if (match != null) {
          entries.add(_ParsedEntry(match.group(0)!));
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
    final dictService = DictionaryService();
    final notebook = Notebook(name: name, createdAt: DateTime.now());
    final created = await notebookRepo.insert(notebook);
    final now = DateTime.now();
    final notebookId = created.id!;

    // Dedup within batch
    final seen = <String>{};
    final words = <Word>[];
    for (final e in _entries) {
      final lower = e.word.toLowerCase().trim();
      if (seen.contains(lower)) continue;
      seen.add(lower);
      words.add(Word(
        notebookId: notebookId,
        text: e.word,
        definitions: e.definition.isNotEmpty ? [e.definition] : [],
        contexts: [WordContext(type: ContextType.fileImport, source: name, timestamp: now)],
        learnedAt: now,
        createdAt: now,
        updatedAt: now,
      ));
    }

    await wordRepo.insertBatch(words);

    // Enrich words with dictionary data before popping
    final wordsWithIds = await wordRepo.getByNotebook(notebookId);
    for (final word in wordsWithIds) {
      try {
        final result = await dictService.lookup(word.text);
        if (result == null) continue;
        final updated = word.copyWith(
          phonetic: result.phonetic,
          partOfSpeech: result.meanings.isNotEmpty ? result.meanings.first.partOfSpeech : null,
          definitions: result.primaryDefinitions,
          exampleSentence: result.exampleSentence,
          exampleTranslation: result.exampleTranslation,
          examples: result.exampleSentence != null ? [result.exampleSentence!] : [],
          tags: result.tag != null ? result.tag!.split(' ') : [],
          updatedAt: DateTime.now(),
        );
        await wordRepo.update(updated);
      } catch (_) {}
    }

    ref.read(dataRefreshTrigger.notifier).state++;
    ref.read(learnStateProvider.notifier).load();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPad = (bottomInset > 0 ? bottomInset : MediaQuery.of(context).padding.bottom) + 24;

    if (_fileName == null) {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomPad + 40),
        child: const Center(child: CircularProgressIndicator(color: AppColors.signalBlue)),
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
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _entries.length,
                itemBuilder: (_, i) {
                  final e = _entries[i];
                  return Dismissible(
                    key: ValueKey('${e.word}_$i'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: const Color(0xFFFF5252),
                      child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                    ),
                    onDismissed: (_) {
                      setState(() => _entries.removeAt(i));
                    },
                    child: Padding(
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
