import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/capture/capture_sheet.dart';
import '../features/settings/api_config_provider.dart';

class BottomPill extends ConsumerWidget {
  const BottomPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final chatEnabled = ref.watch(wordChatEnabledProvider);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0x05FFFFFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(left: 48, right: 48, top: 8, bottom: 24 + bottom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xCC2F5CFF),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _IconPillButton(
                  outlinedIcon: Icons.camera_alt_outlined,
                  filledIcon: Icons.camera_alt,
                  onTap: () => context.push('/capture/photo'),
                ),
                _IconPillButton(
                  outlinedIcon: Icons.edit_note_outlined,
                  filledIcon: Icons.edit_note,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useRootNavigator: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => const ProviderScope(child: CaptureSheet()),
                    );
                  },
                ),
                if (chatEnabled)
                  _IconPillButton(
                    outlinedIcon: Icons.chat_bubble_outline,
                    filledIcon: Icons.chat_bubble,
                    onTap: () => context.push('/chat'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconPillButton extends StatefulWidget {
  final IconData outlinedIcon;
  final IconData filledIcon;
  final VoidCallback onTap;

  const _IconPillButton({
    required this.outlinedIcon,
    required this.filledIcon,
    required this.onTap,
  });

  @override
  State<_IconPillButton> createState() => _IconPillButtonState();
}

class _IconPillButtonState extends State<_IconPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          _pressed ? widget.filledIcon : widget.outlinedIcon,
          size: 24,
          color: Colors.white,
        ),
      ),
    );
  }
}
