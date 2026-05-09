import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../models/notebook.dart';

class NotebookRepository {
  final _db = DatabaseHelper.instance.db;

  Future<List<Notebook>> getAll() async {
    final db = await _db;
    final maps = await db.query('notebooks', orderBy: 'isDefault DESC, createdAt DESC');
    return maps.map((m) => Notebook.fromMap(m)).toList();
  }

  Future<Notebook?> getById(int id) async {
    final db = await _db;
    final maps = await db.query('notebooks', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Notebook.fromMap(maps.first);
  }

  Future<Notebook> insert(Notebook notebook) async {
    final db = await _db;
    final id = await db.insert('notebooks', notebook.toMap());
    return notebook.copyWith(id: id);
  }

  Future<void> update(Notebook notebook) async {
    final db = await _db;
    await db.update('notebooks', notebook.toMap(), where: 'id = ?', whereArgs: [notebook.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('words', where: 'notebookId = ?', whereArgs: [id]);
    await db.delete('notebooks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getWordCount(int notebookId) async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM words WHERE notebookId = ?', [notebookId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
