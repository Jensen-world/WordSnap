import '../models/review_session.dart';
import '../storage/web_storage.dart';

class ReviewRepository {
  final _store = WebStorage();

  Future<ReviewSession?> getToday() async {
    final today = DateTime.now();
    final dateStr = DateTime(today.year, today.month, today.day).toIso8601String();
    final row = _store.getReviewSession(dateStr);
    if (row == null) return null;
    return ReviewSession.fromMap(row);
  }

  Future<ReviewSession> getOrCreateToday() async {
    final existing = await getToday();
    if (existing != null) return existing;
    final today = DateTime.now();
    final dateStr = DateTime(today.year, today.month, today.day).toIso8601String();
    final session = ReviewSession(date: DateTime.parse(dateStr));
    final id = _store.insertReviewSession(session.toMap());
    return session.copyWith(id: id);
  }

  Future<void> update(ReviewSession session) async {
    _store.updateReviewSession(session.toMap());
  }

  Future<List<ReviewSession>> getRecent(int days) async {
    return _store.getRecentReviewSessions(days).map((m) => ReviewSession.fromMap(m)).toList();
  }
}
