import 'package:flutter_test/flutter_test.dart';
import 'package:wordsnap/data/models/word_context.dart';

void main() {
  final now = DateTime(2026, 5, 10, 12, 0, 0);

  group('WordContext', () {
    test('all context types serialize correctly', () {
      for (final type in ContextType.values) {
        final ctx = WordContext(type: type, source: 'test_source', timestamp: now);
        final json = ctx.toJson();
        final restored = WordContext.fromJson(json);

        expect(restored.type, type);
        expect(restored.source, 'test_source');
        expect(restored.timestamp, now);
      }
    });

    test('fromJson handles null source', () {
      final json = {
        'type': 'manual',
        'timestamp': '2026-05-10T12:00:00.000',
      };

      final ctx = WordContext.fromJson(json);
      expect(ctx.type, ContextType.manual);
      expect(ctx.source, null);
    });

    test('toJson omits null source', () {
      final ctx = WordContext(type: ContextType.clipboard, timestamp: now);
      final json = ctx.toJson();
      expect(json.containsKey('source'), false);
    });
  });
}
