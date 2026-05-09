import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../models/word.dart';

class WordRepository {
  final _db = DatabaseHelper.instance.db;

  Future<List<Word>> getByNotebook(int notebookId) async {
    final db = await _db;
    final maps = await db.query('words',
      where: 'notebookId = ?',
      whereArgs: [notebookId],
      orderBy: 'learnedAt DESC',
    );
    return maps.map((m) => Word.fromMap(m)).toList();
  }

  Future<List<Word>> getByNotebookAndStatus(int notebookId, {bool? isNew, bool? isMastered}) async {
    final db = await _db;
    final conditions = <String>['notebookId = ?'];
    final args = <dynamic>[notebookId];
    if (isNew != null) {
      conditions.add('isNew = ?');
      args.add(isNew ? 1 : 0);
    }
    if (isMastered != null) {
      conditions.add('isMastered = ?');
      args.add(isMastered ? 1 : 0);
    }
    final maps = await db.query('words',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'learnedAt DESC',
    );
    return maps.map((m) => Word.fromMap(m)).toList();
  }

  Future<Word?> getById(int id) async {
    final db = await _db;
    final maps = await db.query('words', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Word.fromMap(maps.first);
  }

  Future<Word> insert(Word word) async {
    final db = await _db;
    final id = await db.insert('words', word.toMap());
    return word.copyWith(id: id);
  }

  Future<void> update(Word word) async {
    final db = await _db;
    await db.update('words', word.toMap(), where: 'id = ?', whereArgs: [word.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('words', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getCount({int? notebookId, bool? isNew, bool? isMastered}) async {
    final db = await _db;
    final conditions = <String>[];
    final args = <dynamic>[];
    if (notebookId != null) {
      conditions.add('notebookId = ?');
      args.add(notebookId);
    }
    if (isNew != null) {
      conditions.add('isNew = ?');
      args.add(isNew ? 1 : 0);
    }
    if (isMastered != null) {
      conditions.add('isMastered = ?');
      args.add(isMastered ? 1 : 0);
    }
    final where = conditions.isEmpty ? null : conditions.join(' AND ');
    final whereArgs = conditions.isEmpty ? null : args;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM words${where != null ? ' WHERE $where' : ''}', whereArgs);
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
