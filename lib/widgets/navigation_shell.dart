import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/colors.dart';
import '../features/capture/share_receipt_sheet.dart';
import 'capsule_tab_bar.dart';
import 'bottom_pill.dart';

class NavigationShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const NavigationShell({super.key, required this.navigationShell});

  @override
  ConsumerState<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends ConsumerState<NavigationShell> {
  static const _shareChannel = MethodChannel('com.wordsnap/share');
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    _initShareListener();
  }

  @override
  void dispose() {
    _shareChannel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _initShareListener() async {
    _shareChannel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedText') {
        final text = call.arguments as String;
        if (mounted) _handleSharedText(text.trim());
      }
    });
    try {
      final text = await _shareChannel.invokeMethod<String>('getSharedText');
      if (text != null && text.isNotEmpty && mounted) {
        _handleSharedText(text.trim());
      }
    } on MissingPluginException {
      // Expected on non-Android platforms
    }
  }

  void _handleSharedText(String text) {
    if (text.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ShareReceiptSheet(sharedText: text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } else {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('再按一次退出')),
          );
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: const Color(0xFFF9F9FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          toolbarHeight: 72,
          titleSpacing: 16,
          title: Image.asset(
            'assets/logo/wordmark.png',
            height: 44,
          ),
          actions: [
            _SettingsIconButton(onTap: () => context.push('/settings')),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFF0F0F5))),
                  ),
                  child: CapsuleTabBar(
                    currentIndex: widget.navigationShell.currentIndex,
                    onTap: (i) => widget.navigationShell.goBranch(i),
                  ),
                ),
                Expanded(child: widget.navigationShell),
              ],
            ),
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.42,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0x4D2F5CFF), Color(0x002F5CFF)],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const BottomPill(),
      ),
    );
  }
}

class _SettingsIconButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SettingsIconButton({required this.onTap});

  @override
  State<_SettingsIconButton> createState() => _SettingsIconButtonState();
}

class _SettingsIconButtonState extends State<_SettingsIconButton> {
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
        padding: const EdgeInsets.all(12),
        child: Image.asset(
          'assets/icons/settings.png',
          width: 24,
          height: 24,
          color: _pressed ? AppColors.signalBlue : const Color(0xFFBBBBBB),
        ),
      ),
    );
  }
}
