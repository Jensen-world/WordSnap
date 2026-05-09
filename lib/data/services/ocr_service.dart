import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'package:tesseract_ocr/ocr_engine_config.dart';

class OcrResult {
  final String fullText;
  final List<String> words;

  OcrResult({required this.fullText, required this.words});
}

class OcrService {
  Future<OcrResult> processImage(String imagePath) async {
    final fullText = await TesseractOcr.extractText(
      imagePath,
      config: OCRConfig(language: 'eng'),
    );
    final words = _extractEnglishWords(fullText);
    return OcrResult(fullText: fullText.trim(), words: words);
  }

  List<String> _extractEnglishWords(String text) {
    final regex = RegExp(r'\b[a-zA-Z]{2,}\b');
    final matches = regex.allMatches(text);
    final seen = <String>{};
    return matches
        .map((m) => m.group(0)!)
        .where((w) => seen.add(w.toLowerCase()))
        .toList();
  }

  void dispose() {}
}
