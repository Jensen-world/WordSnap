import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class CapsuleTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CapsuleTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 10),
      child: Row(
        children: [
          _TabChip(
            label: '记单词',
            active: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          const SizedBox(width: 6),
          _TabChip(
            label: '单词本',
            active: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          const SizedBox(width: 6),
          _TabChip(
            label: '档案卡',
            active: currentIndex == 2,
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.signalBlue : const Color(0xFFF0F0F5),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : const Color(0xFF999999),
          ),
        ),
      ),
    );
  }
}
