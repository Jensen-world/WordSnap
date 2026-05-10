import 'package:flutter_test/flutter_test.dart';
import 'package:wordsnap/data/models/review_session.dart';

void main() {
  final today = DateTime(2026, 5, 10);

  group('ReviewSession', () {
    test('toMap and fromMap roundtrip', () {
      final session = ReviewSession(
        id: 1,
        date: today,
        wordsReviewed: 15,
        newWordsLearned: 10,
        reviewWordsCorrect: 4,
        reviewWordsWrong: 1,
        isCompleted: true,
      );

      final restored = ReviewSession.fromMap(session.toMap());

      expect(restored.id, 1);
      expect(restored.date, today);
      expect(restored.wordsReviewed, 15);
      expect(restored.newWordsLearned, 10);
      expect(restored.reviewWordsCorrect, 4);
      expect(restored.reviewWordsWrong, 1);
      expect(restored.isCompleted, true);
    });

    test('defaults', () {
      final session = ReviewSession(date: today);
      expect(session.wordsReviewed, 0);
      expect(session.newWordsLearned, 0);
      expect(session.reviewWordsCorrect, 0);
      expect(session.reviewWordsWrong, 0);
      expect(session.isCompleted, false);
    });

    test('copyWith updates fields', () {
      final original = ReviewSession(date: today, wordsReviewed: 0);

      final updated = original.copyWith(
        wordsReviewed: 20,
        isCompleted: true,
      );

      expect(updated.wordsReviewed, 20);
      expect(updated.isCompleted, true);
      expect(updated.newWordsLearned, 0); // unchanged
    });
  });
}
