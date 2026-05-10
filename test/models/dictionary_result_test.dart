import 'package:flutter_test/flutter_test.dart';
import 'package:wordsnap/data/services/dictionary_result.dart';

void main() {
  group('DictionaryResult.fromEcdict', () {
    test('parses full ECDICT row', () {
      final row = {
        'word': 'test',
        'phonetic': 'tɛst',
        'definition': 'a procedure for critical evaluation\nan examination',
        'translation': 'n. 测试，试验',
        'pos': 'n',
        'exchange': 'tests/testing/tested',
        'tag': 'cet4 cet6 ielts',
      };

      final result = DictionaryResult.fromEcdict(row);

      expect(result.word, 'test');
      expect(result.phonetic, 'tɛst');
      expect(result.translation, 'n. 测试，试验');
      expect(result.exchange, 'tests/testing/tested');
      expect(result.tag, 'cet4 cet6 ielts');
      expect(result.meanings.length, 1);
      expect(result.meanings[0].partOfSpeech, 'noun');
      expect(result.meanings[0].definitions.length, 2);
      expect(result.meanings[0].definitions[0].definition,
          'a procedure for critical evaluation');
      expect(result.meanings[0].definitions[1].definition, 'an examination');
    });

    test('handles missing optional fields', () {
      final row = {
        'word': 'hello',
        'phonetic': null,
        'definition': 'a greeting',
        'translation': null,
        'pos': null,
        'exchange': null,
        'tag': null,
      };

      final result = DictionaryResult.fromEcdict(row);

      expect(result.word, 'hello');
      expect(result.phonetic, null);
      expect(result.translation, null);
      expect(result.meanings.length, 1);
      expect(result.meanings[0].partOfSpeech, '');
      expect(result.meanings[0].definitions.length, 1);
    });

    test('handles empty definition string', () {
      final row = {
        'word': 'empty',
        'phonetic': null,
        'definition': '',
        'translation': null,
        'pos': null,
        'exchange': null,
        'tag': null,
      };

      final result = DictionaryResult.fromEcdict(row);
      expect(result.meanings[0].definitions, []);
    });

    test('_expandPos maps all known POS codes', () {
      // Test via fromEcdict with compound POS
      final row = {
        'word': 'run',
        'phonetic': 'rʌn',
        'definition': 'move fast',
        'translation': '跑',
        'pos': 'vi/vt/n',
        'exchange': null,
        'tag': null,
      };

      final result = DictionaryResult.fromEcdict(row);
      expect(result.meanings[0].partOfSpeech, 'verb/verb/noun');
    });
  });

  group('DictionaryResult.fromJson (Free Dictionary API format)', () {
    test('parses standard API response', () {
      final json = {
        'word': 'test',
        'phonetics': [
          {'text': '/tɛst/', 'audio': 'https://example.com/test.mp3'},
        ],
        'meanings': [
          {
            'partOfSpeech': 'noun',
            'definitions': [
              {
                'definition': 'a procedure for critical evaluation',
                'example': 'This is a test.',
              },
            ],
          },
          {
            'partOfSpeech': 'verb',
            'definitions': [
              {'definition': 'to subject to a test', 'example': null},
            ],
          },
        ],
      };

      final result = DictionaryResult.fromJson(json);

      expect(result.word, 'test');
      expect(result.phonetic, '/tɛst/');
      expect(result.audioUrl, 'https://example.com/test.mp3');
      expect(result.meanings.length, 2);
      expect(result.meanings[0].partOfSpeech, 'noun');
      expect(result.meanings[1].partOfSpeech, 'verb');
    });

    test('handles empty phonetics and meanings', () {
      final json = {
        'word': 'minimal',
        'phonetics': [],
        'meanings': [],
      };

      final result = DictionaryResult.fromJson(json);
      expect(result.phonetic, null);
      expect(result.audioUrl, null);
      expect(result.meanings, []);
    });
  });
}
