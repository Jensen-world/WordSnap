import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/colors.dart';
import '../../data/models/notebook.dart';
import '../wordbook/wordbook_provider.dart';
import '../learn/learn_provider.dart';
import 'photo_capture_provider.dart';

class PhotoCapturePage extends ConsumerStatefulWidget {
  const PhotoCapturePage({super.key});

  @override
  ConsumerState<PhotoCapturePage> createState() => _PhotoCapturePageState();
}

class _PhotoCapturePageState extends ConsumerState<PhotoCapturePage> {
  final _picker = ImagePicker();
  bool _cameraOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openCamera());
  }

  Future<void> _openCamera() async {
    if (_cameraOpened) return;
    _cameraOpened = true;
    try {
      final xfile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
      if (xfile != null && mounted) {
        ref.read(photoCaptureProvider.notifier).processImage(xfile.path);
      } else if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(photoCaptureProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('拍照识别'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (state.step == PhotoStep.ready || state.step == PhotoStep.result)
            TextButton(
              onPressed: () => ref.read(photoCaptureProvider.notifier).retake(),
              child: const Text('重拍', style: TextStyle(color: AppColors.signalBlue)),
            ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(PhotoCaptureState state) {
    switch (state.step) {
      case PhotoStep.initial:
      case PhotoStep.processing:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.signalBlue),
              SizedBox(height: 16),
              Text('正在识别文字...', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
            ],
          ),
        );
      case PhotoStep.ready:
        return _readyView(state);
      case PhotoStep.lookingUp:
        return _readyView(state, showLookupSpinner: true);
      case PhotoStep.result:
        return _resultView(state);
      case PhotoStep.saving:
        return _resultView(state, showSaveSpinner: true);
      case PhotoStep.done:
        return _doneView();
    }
  }

  Widget _readyView(PhotoCaptureState state, {bool showLookupSpinner = false}) {
    final bottomPad = 20 + MediaQuery.of(context).padding.bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad),
      children: [
        if (state.imagePath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(state.imagePath!), height: 200, width: double.infinity, fit: BoxFit.cover),
          ),
        if (state.imagePath != null) const SizedBox(height: 16),
        if (state.fullText.isNotEmpty) ...[
          const Text('识别全文', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E2EA)),
            ),
            child: Text(state.fullText, style: const TextStyle(fontSize: 13, color: AppColors.inkBlack)),
          ),
          const SizedBox(height: 16),
        ],
        if (showLookupSpinner)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Center(child: CircularProgressIndicator(color: AppColors.signalBlue)),
          ),
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              state.errorMessage!,
              style: const TextStyle(fontSize: 13, color: Color(0xFFFF5252)),
              textAlign: TextAlign.center,
            ),
          ),
        const Text('识别到的单词', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
        const SizedBox(height: 8),
        if (state.words.isEmpty)
          const Text('未识别到英文单词', style: TextStyle(fontSize: 14, color: Color(0xFF999999)))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.words.map((w) => _WordChip(
              word: w,
              selected: w == state.selectedWord,
              onTap: () {
                ref.read(photoCaptureProvider.notifier).loadNotebooks();
                ref.read(photoCaptureProvider.notifier).lookup(w);
              },
            )).toList(),
          ),
      ],
    );
  }

  Widget _resultView(PhotoCaptureState state, {bool showSaveSpinner = false}) {
    final result = state.lookupResult!;
    final bottomPad = 20 + MediaQuery.of(context).padding.bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad),
      children: [
        _ResultCard(result: result),
        const SizedBox(height: 24),
        const Text('存入', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
        const SizedBox(height: 8),
        _NotebookSelector(
          notebooks: state.notebooks,
          selectedId: state.selectedNotebookId,
          onSelected: (id) => ref.read(photoCaptureProvider.notifier).setNotebook(id),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => ref.read(photoCaptureProvider.notifier).backToWords(),
                child: const Text('返回选词', style: TextStyle(color: Color(0xFF999999))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: showSaveSpinner ? null : () => _save(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.signalBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                child: showSaveSpinner
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('确认添加', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _doneView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 20),
          const Text('已添加', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.inkBlack)),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () => ref.read(photoCaptureProvider.notifier).retake(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E2EA)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                child: const Text('再拍一张', style: TextStyle(color: AppColors.inkBlack)),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () {
                  ref.read(dataRefreshTrigger.notifier).state++;
                  ref.read(learnStateProvider.notifier).load();
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.signalBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                child: const Text('完成'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    try {
      await ref.read(photoCaptureProvider.notifier).save();
      ref.read(dataRefreshTrigger.notifier).state++;
      ref.read(learnStateProvider.notifier).load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败')),
        );
      }
    }
  }
}

class _WordChip extends StatelessWidget {
  final String word;
  final bool selected;
  final VoidCallback onTap;

  const _WordChip({required this.word, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.signalBlue : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: selected ? AppColors.signalBlue : const Color(0xFFE2E2EA)),
        ),
        child: Text(
          word,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.inkBlack,
          ),
        ),
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
          Text(result.word, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.inkBlack)),
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
          border: Border.all(color: const Color(0xFFE2E2EA)),
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
