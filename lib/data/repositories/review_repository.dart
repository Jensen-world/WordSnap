import '../../core/database/database_helper.dart';
import '../models/review_session.dart';

class ReviewRepository {
  final _db = DatabaseHelper.instance.db;

  Future<ReviewSession?> getToday() async {
    final db = await _db;
    final today = DateTime.now();
    final dateStr = DateTime(today.year, today.month, today.day).toIso8601String();
    final maps = await db.query('review_sessions', where: 'date = ?', whereArgs: [dateStr]);
    if (maps.isEmpty) return null;
    return ReviewSession.fromMap(maps.first);
  }

  Future<ReviewSession> getOrCreateToday() async {
    final existing = await getToday();
    if (existing != null) return existing;
    final db = await _db;
    final today = DateTime.now();
    final dateStr = DateTime(today.year, today.month, today.day).toIso8601String();
    final session = ReviewSession(date: DateTime.parse(dateStr));
    final id = await db.insert('review_sessions', session.toMap());
    return session.copyWith(id: id);
  }

  Future<void> update(ReviewSession session) async {
    final db = await _db;
    await db.update('review_sessions', session.toMap(), where: 'id = ?', whereArgs: [session.id]);
  }

  Future<List<ReviewSession>> getRecent(int days) async {
    final db = await _db;
    final maps = await db.query('review_sessions',
      orderBy: 'date DESC',
      limit: days,
    );
    return maps.map((m) => ReviewSession.fromMap(m)).toList();
  }
}
