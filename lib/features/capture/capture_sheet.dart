import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import 'capture_provider.dart';

class CaptureSheet extends ConsumerStatefulWidget {
  const CaptureSheet({super.key});

  @override
  ConsumerState<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends ConsumerState<CaptureSheet> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(captureStateProvider.notifier).reset();
    Future.microtask(() => ref.read(captureStateProvider.notifier).loadNotebooks());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final word = _controller.text.trim();
    if (word.isEmpty) return;
    ref.read(captureStateProvider.notifier).setInput(word);
    ref.read(captureStateProvider.notifier).lookup();
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push('/capture/result');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPad = (bottomInset > 0 ? bottomInset : MediaQuery.of(context).padding.bottom) + 24;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFDDDDDD),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '输入单词',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.inkBlack),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _confirm(),
            decoration: const InputDecoration(
              hintText: '请输入或粘贴你想记录的单词',
              hintStyle: TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _confirm,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.signalBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: const Text('查询', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
