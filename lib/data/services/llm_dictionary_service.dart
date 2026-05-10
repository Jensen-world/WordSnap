import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dictionary_result.dart';

class LlmDictionaryService {
  static const _prompt = '''You are a concise dictionary assistant. For the given word, return ONLY a JSON object (no markdown, no extra text):

{"phonetic":"IPA phonetic (US)","definition":"Chinese definition (concise, 1-2 meanings max)","example":"English example sentence","exampleTranslation":"Chinese translation of example"}

Word:''';

  /// Returns null on success, or an error message string on failure.
  Future<String?> testConnection({
    required String baseUrl,
    required String apiKey,
    required String model,
  }) async {
    final url = '${baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl}/chat/completions';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': 'Say "ok"'},
          ],
          'max_tokens': 16,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return 'HTTP ${response.statusCode}: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}';
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return '响应无 choices: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}';
      }
      return null; // success
    } catch (e) {
      return '$e';
    }
  }

  Future<DictionaryResult?> lookup(
    String word, {
    required String baseUrl,
    required String apiKey,
    required String model,
  }) async {
    final clean = word.trim().toLowerCase();
    if (clean.isEmpty) return null;

    final url = '${baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl}/chat/completions';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': _prompt},
            {'role': 'user', 'content': clean},
          ],
          'temperature': 0.3,
          'max_tokens': 512,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print('LLM API error: ${response.statusCode} ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        print('LLM API: no choices in response: ${response.body}');
        return null;
      }

      final content = choices.first['message']?['content'] as String?;
      if (content == null) {
        print('LLM API: no content in message');
        return null;
      }

      final start = content.indexOf('{');
      final end = content.lastIndexOf('}');
      if (start == -1 || end == -1) {
        print('LLM API: no JSON in content: $content');
        return null;
      }

      final json = jsonDecode(content.substring(start, end + 1)) as Map<String, dynamic>;
      print('LLM success: ${json['definition']}');
      return DictionaryResult.fromLlmJson({
        'word': clean,
        'phonetic': json['phonetic'],
        'definition': json['definition'],
        'example': json['example'],
        'exampleTranslation': json['exampleTranslation'],
      });
    } catch (e) {
      print('LLM exception: $e');
      return null;
    }
  }
}
