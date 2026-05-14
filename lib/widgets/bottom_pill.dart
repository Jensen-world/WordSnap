import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/capture/capture_sheet.dart';
import '../features/settings/api_config_provider.dart';
import '../features/wordbook/import_wordlist_sheet.dart';

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
          padding: EdgeInsets.only(left: 20, right: 20, top: 6, bottom: 18 + bottom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xCC2F5CFF),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _IconPillButton(
                  outlinedAsset: 'assets/icons/pill_camera_outlined.png',
                  filledAsset: 'assets/icons/pill_camera_filled.png',
                  onTap: () => context.push('/capture/photo'),
                ),
                _IconPillButton(
                  outlinedAsset: 'assets/icons/pill_edit_outlined.png',
                  filledAsset: 'assets/icons/pill_edit_filled.png',
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
                _IconPillButton(
                  outlinedAsset: 'assets/icons/pill_upload_outlined.png',
                  filledAsset: 'assets/icons/pill_upload_filled.png',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useRootNavigator: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => const ProviderScope(child: ImportWordlistSheet()),
                    );
                  },
                ),
                if (chatEnabled)
                  _IconPillButton(
                    outlinedAsset: 'assets/icons/pill_chat_outlined.png',
                    filledAsset: 'assets/icons/pill_chat_filled.png',
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
  final String outlinedAsset;
  final String filledAsset;
  final VoidCallback onTap;

  const _IconPillButton({
    required this.outlinedAsset,
    required this.filledAsset,
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
        child: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset(
            _pressed ? widget.filledAsset : widget.outlinedAsset,
            width: 24,
            height: 24,
          ),
        ),
      ),
    );
  }
}
