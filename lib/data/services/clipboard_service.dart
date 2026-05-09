import 'dart:async';
import 'package:flutter/services.dart';

class ClipboardService {
  Timer? _timer;
  String _lastContent = '';
  void Function(String text)? onDetect;

  void startMonitoring({Duration interval = const Duration(seconds: 2)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _check());
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _check() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty || text == _lastContent) return;
    _lastContent = text;
    onDetect?.call(text);
  }

  Future<String?> getClipboardText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text?.trim();
  }

  void dispose() {
    stopMonitoring();
  }
}
