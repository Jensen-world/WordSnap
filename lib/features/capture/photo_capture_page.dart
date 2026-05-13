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
  final String? source;

  const PhotoCapturePage({super.key, this.source});

  @override
  ConsumerState<PhotoCapturePage> createState() => _PhotoCapturePageState();
}

class _PhotoCapturePageState extends ConsumerState<PhotoCapturePage> {
  final _picker = ImagePicker();
  bool _cameraOpened = false;
  final _imageKey = GlobalKey();
  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;

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
          if (state.step == PhotoStep.selecting || state.step == PhotoStep.result)
            TextButton(
              onPressed: () {
                setState(() { _strokes.clear(); _currentStroke = null; });
                _cameraOpened = false;
                ref.read(photoCaptureProvider.notifier).retake();
                WidgetsBinding.instance.addPostFrameCallback((_) => _openCamera());
              },
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
              Text('正在打开相机...', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
            ],
          ),
        );
      case PhotoStep.selecting:
        return _buildSelectingView(state);
      case PhotoStep.lookingUp:
        return _buildSelectingView(state, showLookupSpinner: true);
      case PhotoStep.result:
        if (widget.source == 'chat') return _chatConfirmView(state);
        return _resultView(state);
      case PhotoStep.saving:
        return _resultView(state, showSaveSpinner: true);
      case PhotoStep.done:
        if (widget.source == 'chat') return const SizedBox.shrink();
        return _doneView();
    }
  }

  Widget _buildSelectingView(PhotoCaptureState state, {bool showLookupSpinner = false}) {
    final bottomPad = 20 + MediaQuery.of(context).padding.bottom;
    return Column(
      children: [
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(state.errorMessage!, style: const TextStyle(fontSize: 13, color: Color(0xFFFF5252)), textAlign: TextAlign.center),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('涂抹选中要查的单词', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onPanStart: (d) {
                setState(() {
                  _currentStroke = [d.localPosition];
                  _strokes.add(_currentStroke!);
                });
              },
              onPanUpdate: (d) {
                setState(() => _currentStroke?.add(d.localPosition));
              },
              onPanEnd: (_) => setState(() => _currentStroke = null),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(state.imagePath!), key: _imageKey, fit: BoxFit.contain),
                    if (showLookupSpinner)
                      Container(color: const Color(0x80FFFFFF), child: const Center(child: CircularProgressIndicator(color: AppColors.signalBlue))),
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: _HighlighterPainter(strokes: _strokes),
                        size: Size.infinite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: bottomPad < 80 ? 8 : 16),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _strokes.isNotEmpty ? () => setState(() => _strokes.removeLast()) : null,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E2EA)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  child: const Text('撤销', style: TextStyle(color: Color(0xFF999999))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _strokes.isEmpty ? null : () => _confirmCrop(state),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.signalBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  child: const Text('确认', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmCrop(PhotoCaptureState state) {
    if (_strokes.isEmpty || state.imagePath == null) return;

    // Calculate bounding rect of all stroke points
    double minX = double.infinity, minY = double.infinity, maxX = 0, maxY = 0;
    for (final stroke in _strokes) {
      for (final point in stroke) {
        if (point.dx < minX) minX = point.dx;
        if (point.dy < minY) minY = point.dy;
        if (point.dx > maxX) maxX = point.dx;
        if (point.dy > maxY) maxY = point.dy;
      }
    }

    // Get the image widget's display size
    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    final displayWidth = renderBox?.size.width ?? 300.0;
    final displayHeight = renderBox?.size.height ?? 300.0;

    ref.read(photoCaptureProvider.notifier).loadNotebooks();
    ref.read(photoCaptureProvider.notifier).confirmSelection(
      displayWidth: displayWidth,
      displayHeight: displayHeight,
      cropX: minX,
      cropY: minY,
      cropW: maxX - minX,
      cropH: maxY - minY,
    );

    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
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
                child: const Text('返回涂抹', style: TextStyle(color: Color(0xFF999999))),
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

  Widget _chatConfirmView(PhotoCaptureState state) {
    final result = state.lookupResult!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.word,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.inkBlack),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () {
                    ref.read(photoCaptureProvider.notifier).backToWords();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E2EA)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  child: const Text('重试', style: TextStyle(color: Color(0xFF999999))),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(result.word),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.signalBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  child: const Text('确认'),
                ),
              ],
            ),
          ],
        ),
      ),
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
                onPressed: () {
                  _cameraOpened = false;
                  ref.read(photoCaptureProvider.notifier).retake();
                  WidgetsBinding.instance.addPostFrameCallback((_) => _openCamera());
                },
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is Exception ? e.toString().replaceFirst('Exception: ', '') : '保存失败')),
        );
      }
    }
  }
}

class _HighlighterPainter extends CustomPainter {
  final List<List<Offset>> strokes;

  const _HighlighterPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x4D2F5CFF)
      ..strokeWidth = 36
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HighlighterPainter old) => true;
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
