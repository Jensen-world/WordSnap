import 'package:flutter_test/flutter_test.dart';
import 'package:wordsnap/data/models/notebook.dart';

void main() {
  final now = DateTime(2026, 5, 10);

  group('Notebook', () {
    test('toMap and fromMap roundtrip', () {
      final nb = Notebook(
        id: 1,
        name: '拾词集',
        isDefault: true,
        dailyNewWordLimit: 10,
        createdAt: now,
      );

      final restored = Notebook.fromMap(nb.toMap());

      expect(restored.id, 1);
      expect(restored.name, '拾词集');
      expect(restored.isDefault, true);
      expect(restored.dailyNewWordLimit, 10);
      expect(restored.createdAt, now);
    });

    test('fromMap handles defaults', () {
      final map = {
        'id': 1,
        'name': 'test',
        'isDefault': 0,
        'createdAt': '2026-05-10T00:00:00.000',
      };

      final nb = Notebook.fromMap(map);
      expect(nb.isDefault, false);
      expect(nb.dailyNewWordLimit, 0);
    });

    test('copyWith updates individual fields', () {
      final original = Notebook(
        name: 'Old',
        isDefault: false,
        dailyNewWordLimit: 5,
        createdAt: now,
      );

      final updated = original.copyWith(name: 'New', dailyNewWordLimit: 20);

      expect(updated.name, 'New');
      expect(updated.dailyNewWordLimit, 20);
      expect(updated.isDefault, false);
      expect(updated.id, null);
    });

    test('toMap excludes null id', () {
      final nb = Notebook(name: 'test', createdAt: now);
      expect(nb.toMap().containsKey('id'), false);
    });
  });
}
