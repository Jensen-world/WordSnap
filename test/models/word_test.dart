import 'package:flutter_test/flutter_test.dart';
import 'package:wordsnap/data/models/word.dart';
import 'package:wordsnap/data/models/word_context.dart';

void main() {
  final now = DateTime(2026, 5, 10, 12, 0, 0);

  group('Word', () {
    test('toMap and fromMap roundtrip', () {
      final word = Word(
        id: 1,
        notebookId: 2,
        text: 'test',
        phonetic: '/tɛst/',
        partOfSpeech: 'noun',
        definitions: ['a procedure for critical evaluation'],
        examples: ['This is a test.'],
        contexts: [
          WordContext(type: ContextType.manual, timestamp: now),
        ],
        tags: ['tag1', 'tag2'],
        sourceUrl: 'https://example.com',
        isPhrase: false,
        isNew: false,
        reviewCount: 5,
        learnedAt: now,
        isMastered: false,
        createdAt: now,
        updatedAt: now,
      );

      final map = word.toMap();
      final restored = Word.fromMap(map);

      expect(restored.id, 1);
      expect(restored.notebookId, 2);
      expect(restored.text, 'test');
      expect(restored.phonetic, '/tɛst/');
      expect(restored.partOfSpeech, 'noun');
      expect(restored.definitions, ['a procedure for critical evaluation']);
      expect(restored.examples, ['This is a test.']);
      expect(restored.contexts.length, 1);
      expect(restored.contexts[0].type, ContextType.manual);
      expect(restored.tags, ['tag1', 'tag2']);
      expect(restored.sourceUrl, 'https://example.com');
      expect(restored.isPhrase, false);
      expect(restored.isNew, false);
      expect(restored.reviewCount, 5);
      expect(restored.isMastered, false);
    });

    test('fromMap handles null fields', () {
      final map = {
        'id': 1,
        'notebookId': 2,
        'text': 'hello',
        'phonetic': null,
        'partOfSpeech': null,
        'definitions': '[]',
        'examples': '[]',
        'contexts': '[]',
        'tags': '[]',
        'sourceUrl': null,
        'isPhrase': 0,
        'isNew': 1,
        'reviewCount': null,
        'learnedAt': '2026-05-10T12:00:00.000',
        'isMastered': 0,
        'createdAt': '2026-05-10T12:00:00.000',
        'updatedAt': '2026-05-10T12:00:00.000',
      };

      final word = Word.fromMap(map);
      expect(word.phonetic, null);
      expect(word.partOfSpeech, null);
      expect(word.reviewCount, 0);
      expect(word.definitions, []);
      expect(word.tags, []);
    });

    test('copyWith updates individual fields', () {
      final original = Word(
        notebookId: 1,
        text: 'original',
        definitions: ['def1'],
        tags: ['a'],
        isNew: true,
        reviewCount: 0,
        learnedAt: now,
        isMastered: false,
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        text: 'updated',
        isNew: false,
        reviewCount: 5,
      );

      // Changed fields
      expect(updated.text, 'updated');
      expect(updated.isNew, false);
      expect(updated.reviewCount, 5);
      // Unchanged fields
      expect(updated.notebookId, 1);
      expect(updated.definitions, ['def1']);
      expect(updated.tags, ['a']);
      expect(updated.isMastered, false);
    });

    test('copyWith with null preserves original', () {
      final original = Word(
        notebookId: 1,
        text: 'test',
        learnedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith();
      expect(updated.text, 'test');
      expect(updated.notebookId, 1);
    });

    test('toMap excludes null id', () {
      final word = Word(
        notebookId: 1,
        text: 'test',
        learnedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final map = word.toMap();
      expect(map.containsKey('id'), false);
    });

    test('toMap includes id when not null', () {
      final word = Word(
        id: 42,
        notebookId: 1,
        text: 'test',
        learnedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      expect(word.toMap()['id'], 42);
    });
  });
}
