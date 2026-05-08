import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/capture/capture_sheet.dart';

class BottomPill extends StatelessWidget {
  const BottomPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: 32 + MediaQuery.of(context).padding.bottom),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xCC2F5CFF),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PillButton(
              icon: Icons.camera_alt_outlined,
              label: '拍照',
              onTap: () => context.push('/capture/photo'),
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 12, color: const Color(0xFFDDDDDD)),
            const SizedBox(width: 8),
            _PillButton(
              icon: Icons.edit_outlined,
              label: '记录',
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => const ProviderScope(child: CaptureSheet()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: const Color(0xFF0B0B0F)),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF0B0B0F))),
            ],
          ),
        ),
      ),
    );
  }
}
