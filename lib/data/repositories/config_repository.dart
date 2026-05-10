import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';

class ConfigRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<String?> get(String key) async {
    final db = await _db.db;
    final rows = await db.query('config', where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> set(String key, String value) async {
    final db = await _db.db;
    await db.insert('config', {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Defaults
  static const defaultBaseUrl = 'https://open.bigmodel.cn/api/paas/v4';
  static const defaultModel = 'glm-4-flash';
}
