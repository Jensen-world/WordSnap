import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _dbName = 'wordsnap.db';
  static const _dbVersion = 2;

  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, _dbName),
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notebooks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        isDefault INTEGER NOT NULL DEFAULT 0,
        dailyNewWordLimit INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        notebookId INTEGER NOT NULL,
        text TEXT NOT NULL,
        phonetic TEXT,
        partOfSpeech TEXT,
        definitions TEXT NOT NULL DEFAULT '[]',
        examples TEXT NOT NULL DEFAULT '[]',
        contexts TEXT NOT NULL DEFAULT '[]',
        tags TEXT NOT NULL DEFAULT '[]',
        sourceUrl TEXT,
        isPhrase INTEGER NOT NULL DEFAULT 0,
        isNew INTEGER NOT NULL DEFAULT 1,
        reviewCount INTEGER NOT NULL DEFAULT 0,
        learnedAt TEXT NOT NULL,
        isMastered INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (notebookId) REFERENCES notebooks(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE review_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        wordsReviewed INTEGER NOT NULL DEFAULT 0,
        newWordsLearned INTEGER NOT NULL DEFAULT 0,
        reviewWordsCorrect INTEGER NOT NULL DEFAULT 0,
        reviewWordsWrong INTEGER NOT NULL DEFAULT 0,
        isCompleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('CREATE INDEX idx_words_notebook ON words(notebookId)');
    await db.execute('CREATE INDEX idx_words_isNew ON words(isNew)');
    await db.execute('CREATE INDEX idx_words_isMastered ON words(isMastered)');
    await db.execute('CREATE INDEX idx_words_learnedAt ON words(learnedAt)');

    final now = DateTime.now().toIso8601String();
    await db.insert('notebooks', {
      'name': '拾词集',
      'isDefault': 1,
      'dailyNewWordLimit': 10,
      'createdAt': now,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v1 → v2: schema unchanged, no migration needed
    // Future migrations: use ALTER TABLE, never DROP TABLE
  }
}
