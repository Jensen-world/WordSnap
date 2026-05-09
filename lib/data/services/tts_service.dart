import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.speak(text);
  }

  void stop() => _flutterTts.stop();
}
