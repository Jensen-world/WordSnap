import 'dart:io';
import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'package:tesseract_ocr/ocr_engine_config.dart';
import 'package:image/image.dart' as img;

class OcrResult {
  final String fullText;
  final List<String> words;

  OcrResult({required this.fullText, required this.words});
}

class OcrService {
  Future<OcrResult> processImage(String imagePath) async {
    final preprocessedPath = await _preprocess(imagePath);
    try {
      final fullText = await TesseractOcr.extractText(
        preprocessedPath,
        config: const OCRConfig(language: 'eng'),
      );
      final words = _extractEnglishWords(fullText);
      return OcrResult(fullText: fullText.trim(), words: words);
    } finally {
      if (preprocessedPath != imagePath) {
        try { File(preprocessedPath).deleteSync(); } catch (_) {}
      }
    }
  }

  Future<String> _preprocess(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return imagePath;

      // Grayscale + contrast enhancement for screen text
      // Grayscale to reduce color noise from screen photos
      final grayscale = img.grayscale(decoded);
      final preprocessed = img.encodePng(grayscale);

      final tmp = File('${imagePath}_ocr.png');
      await tmp.writeAsBytes(preprocessed);
      return tmp.path;
    } catch (_) {
      return imagePath;
    }
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

  /// Crop the image to a region defined in display coordinates, OCR the cropped
  /// area, and return the first English word found.
  Future<String?> processCroppedRegion(
    String imagePath, {
    required int imageWidth,
    required int imageHeight,
    required double displayWidth,
    required double displayHeight,
    required double cropX,
    required double cropY,
    required double cropW,
    required double cropH,
  }) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final scaleX = imageWidth / displayWidth;
      final scaleY = imageHeight / displayHeight;
      const padding = 20.0;

      final x = ((cropX - padding) * scaleX).clamp(0, imageWidth).toInt();
      final y = ((cropY - padding) * scaleY).clamp(0, imageHeight).toInt();
      final w = ((cropW + padding * 2) * scaleX).clamp(0, imageWidth - x).toInt();
      final h = ((cropH + padding * 2) * scaleY).clamp(0, imageHeight - y).toInt();

      if (w <= 0 || h <= 0) return null;

      final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
      final grayscale = img.grayscale(cropped);
      final preprocessed = img.encodePng(grayscale);

      final tmp = File('${imagePath}_crop.png');
      await tmp.writeAsBytes(preprocessed);
      try {
        final text = await TesseractOcr.extractText(
          tmp.path,
          config: const OCRConfig(language: 'eng'),
        );
        final words = _extractEnglishWords(text);
        return words.isNotEmpty ? words.first : null;
      } finally {
        try { tmp.deleteSync(); } catch (_) {}
      }
    } catch (_) {
      return null;
    }
  }

  void dispose() {}
}
