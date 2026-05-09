import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class CreateNotebookSheet extends StatefulWidget {
  final String? initialName;

  const CreateNotebookSheet({super.key, this.initialName});

  @override
  State<CreateNotebookSheet> createState() => _CreateNotebookSheetState();
}

class _CreateNotebookSheetState extends State<CreateNotebookSheet> {
  late final TextEditingController _controller;

  bool get isEditing => widget.initialName != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isEditing ? '编辑单词本' : '新建单词本',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.inkBlack),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            '名称',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: !isEditing,
            decoration: const InputDecoration(
              hintText: '输入单词本名称...',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.signalBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: Text(isEditing ? '保存' : '创建', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('取消', style: TextStyle(color: Color(0xFF999999))),
          ),
        ],
      ),
    );
  }
}
