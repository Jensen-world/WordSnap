import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _dbName = 'wordsnap.db';
  static const _dbVersion = 5;

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
        exampleSentence TEXT,
        exampleTranslation TEXT,
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
      CREATE TABLE dictionary_cache (
        word TEXT PRIMARY KEY,
        phonetic TEXT,
        definition TEXT,
        exampleSentence TEXT,
        exampleTranslation TEXT,
        source TEXT NOT NULL DEFAULT 'llm',
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE config (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
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

    await db.execute('''
      CREATE TABLE chat_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mode TEXT NOT NULL DEFAULT 'local',
        anchored_word TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE word_chat (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        wordId INTEGER,
        word TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        session_id INTEGER,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (wordId) REFERENCES words(id) ON DELETE SET NULL,
        FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_words_notebook ON words(notebookId)');
    await db.execute('CREATE INDEX idx_words_isNew ON words(isNew)');
    await db.execute('CREATE INDEX idx_words_isMastered ON words(isMastered)');
    await db.execute('CREATE INDEX idx_words_learnedAt ON words(learnedAt)');
    await db.execute('CREATE INDEX idx_word_chat_word ON word_chat(word)');
    await db.execute('CREATE INDEX idx_word_chat_session ON word_chat(session_id)');

    final now = DateTime.now().toIso8601String();
    await db.insert('notebooks', {
      'name': '拾词集',
      'isDefault': 1,
      'dailyNewWordLimit': 0,
      'createdAt': now,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE words ADD COLUMN exampleSentence TEXT");
      await db.execute("ALTER TABLE words ADD COLUMN exampleTranslation TEXT");
      await db.execute('''
        CREATE TABLE IF NOT EXISTS dictionary_cache (
          word TEXT PRIMARY KEY,
          phonetic TEXT,
          definition TEXT,
          exampleSentence TEXT,
          exampleTranslation TEXT,
          source TEXT NOT NULL DEFAULT 'llm',
          createdAt TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS config (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mode TEXT NOT NULL DEFAULT 'local',
          anchored_word TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('ALTER TABLE word_chat ADD COLUMN session_id INTEGER');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_word_chat_session ON word_chat(session_id)');
    }
  }
}
