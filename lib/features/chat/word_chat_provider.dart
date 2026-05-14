import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/dictionary_result.dart';
import '../../data/services/dictionary_service.dart';
import '../../data/services/llm_dictionary_service.dart';
import '../../data/repositories/config_repository.dart';
import '../../core/database/database_helper.dart';

enum ChatMode { local, ai }

class ChatSession {
  final int? id;
  final ChatMode mode;
  final String? anchoredWord;
  final int messageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatSession({
    this.id,
    this.mode = ChatMode.local,
    this.anchoredWord,
    this.messageCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'mode': mode.name,
    'anchored_word': anchoredWord,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ChatSession.fromMap(Map<String, dynamic> map) => ChatSession(
    id: map['id'] as int,
    mode: map['mode'] == 'ai' ? ChatMode.ai : ChatMode.local,
    anchoredWord: map['anchored_word'] as String?,
    messageCount: map['message_count'] as int? ?? 0,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );
}

class ChatMessage {
  final int? id;
  final String role;
  final String content;
  final String word;
  final int? sessionId;
  final DateTime createdAt;

  const ChatMessage({
    this.id,
    required this.role,
    required this.content,
    required this.word,
    this.sessionId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'word': word,
    'role': role,
    'content': content,
    if (sessionId != null) 'session_id': sessionId,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    id: map['id'] as int,
    role: map['role'] as String,
    content: map['content'] as String,
    word: map['word'] as String,
    sessionId: map['session_id'] as int?,
    createdAt: DateTime.parse(map['createdAt'] as String),
  );
}

class WordChatState {
  final List<ChatSession> sessions;
  final int? currentSessionId;
  final List<ChatMessage> messages;
  final ChatMode mode;
  final bool isStreaming;
  final DictionaryResult? localResult;
  final bool localLoading;
  final String? anchoredWord;

  const WordChatState({
    this.sessions = const [],
    this.currentSessionId,
    this.messages = const [],
    this.mode = ChatMode.local,
    this.isStreaming = false,
    this.localResult,
    this.localLoading = false,
    this.anchoredWord,
  });

  WordChatState copyWith({
    List<ChatSession>? sessions,
    int? currentSessionId,
    List<ChatMessage>? messages,
    ChatMode? mode,
    bool? isStreaming,
    DictionaryResult? localResult,
    bool clearLocalResult = false,
    bool? localLoading,
    String? anchoredWord,
  }) => WordChatState(
    sessions: sessions ?? this.sessions,
    currentSessionId: currentSessionId ?? this.currentSessionId,
    messages: messages ?? this.messages,
    mode: mode ?? this.mode,
    isStreaming: isStreaming ?? this.isStreaming,
    localResult: clearLocalResult ? null : (localResult ?? this.localResult),
    localLoading: localLoading ?? this.localLoading,
    anchoredWord: anchoredWord ?? this.anchoredWord,
  );
}

final wordChatProvider = StateNotifierProvider<WordChatNotifier, WordChatState>((ref) {
  return WordChatNotifier();
});

class WordChatNotifier extends StateNotifier<WordChatState> {
  final _dictionaryService = DictionaryService();
  final _llm = LlmDictionaryService();
  final _config = ConfigRepository();

  WordChatNotifier() : super(const WordChatState());

  Future<void> init() async {
    await _loadSessions();
    if (state.currentSessionId != null) {
      await _loadSessionMessages(state.currentSessionId!);
    }
  }

  Future<void> _loadSessions() async {
    try {
      final db = await DatabaseHelper.instance.db;
      final rows = await db.rawQuery('''
        SELECT s.*, COUNT(wc.id) as message_count
        FROM chat_sessions s
        LEFT JOIN word_chat wc ON wc.session_id = s.id
        GROUP BY s.id
        ORDER BY s.updated_at DESC
      ''');
      final sessions = rows.map((r) => ChatSession.fromMap(r)).toList();

      if (sessions.isEmpty) {
        final now = DateTime.now();
        final id = await db.insert('chat_sessions', {
          'mode': 'ai',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
        final newSession = ChatSession(id: id, createdAt: now, updatedAt: now, mode: ChatMode.ai);
        state = state.copyWith(sessions: [newSession], currentSessionId: id, mode: ChatMode.ai);
      } else {
        state = state.copyWith(
          sessions: sessions,
          currentSessionId: sessions.first.id,
          mode: sessions.first.mode,
          anchoredWord: sessions.first.anchoredWord,
        );
      }
    } catch (_) {}
  }

  Future<void> _loadSessionMessages(int sessionId) async {
    try {
      final db = await DatabaseHelper.instance.db;
      final rows = await db.query(
        'word_chat',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'createdAt ASC',
        limit: 100,
      );
      final messages = rows.map((r) => ChatMessage.fromMap(r)).toList();
      state = state.copyWith(messages: messages);
    } catch (_) {}
  }

  Future<void> newSession({ChatMode mode = ChatMode.ai}) async {
    try {
      final db = await DatabaseHelper.instance.db;
      final now = DateTime.now();
      final id = await db.insert('chat_sessions', {
        'mode': mode.name,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      final session = ChatSession(id: id, createdAt: now, updatedAt: now, mode: mode);
      state = state.copyWith(
        sessions: [session, ...state.sessions],
        currentSessionId: id,
        messages: [],
        mode: mode,
        anchoredWord: null,
        clearLocalResult: true,
      );
    } catch (_) {}
  }

  Future<void> switchSession(int sessionId) async {
    if (sessionId == state.currentSessionId) return;
    final session = state.sessions.firstWhere((s) => s.id == sessionId);
    state = state.copyWith(
      currentSessionId: sessionId,
      mode: session.mode,
      anchoredWord: session.anchoredWord,
      messages: [],
      clearLocalResult: true,
    );
    await _loadSessionMessages(sessionId);
  }

  Future<void> deleteSession(int sessionId) async {
    try {
      final db = await DatabaseHelper.instance.db;
      await db.delete('chat_sessions', where: 'id = ?', whereArgs: [sessionId]);
      await db.delete('word_chat', where: 'session_id = ?', whereArgs: [sessionId]);

      final remaining = state.sessions.where((s) => s.id != sessionId).toList();
      if (remaining.isEmpty) {
        await _loadSessions();
      } else {
        state = state.copyWith(sessions: remaining);
        if (state.currentSessionId == sessionId) {
          await switchSession(remaining.first.id!);
        }
      }
    } catch (_) {}
  }

  Future<void> deleteMessage(ChatMessage msg) async {
    if (msg.id == null) return;
    try {
      final db = await DatabaseHelper.instance.db;
      await db.delete('word_chat', where: 'id = ?', whereArgs: [msg.id]);
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != msg.id).toList(),
      );
      _updateSession();
    } catch (_) {}
  }

  void setAnchoredWord(String word) {
    state = state.copyWith(anchoredWord: word);
    _updateSession();
  }

  Future<void> setMode(ChatMode mode) async {
    if (mode == state.mode) return;
    await newSession(mode: mode);
  }

  Future<void> _updateSession() async {
    final sid = state.currentSessionId;
    if (sid == null) return;
    try {
      final db = await DatabaseHelper.instance.db;
      await db.update(
        'chat_sessions',
        {
          'mode': state.mode.name,
          'anchored_word': state.anchoredWord,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [sid],
      );
      _refreshSessionInList(sid);
    } catch (_) {}
  }

  void _refreshSessionInList(int sessionId) {
    final sessions = state.sessions.map((s) {
      if (s.id == sessionId) {
        return ChatSession(
          id: s.id,
          mode: state.mode,
          anchoredWord: state.anchoredWord,
          messageCount: s.messageCount,
          createdAt: s.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      return s;
    }).toList();
    state = state.copyWith(sessions: sessions);
  }

  Future<void> localLookup(String word) async {
    final clean = word.trim();
    if (clean.isEmpty) return;
    await newSession(mode: ChatMode.local);
    state = state.copyWith(localLoading: true, anchoredWord: clean);
    _updateSession();

    try {
      final result = await _dictionaryService.lookup(clean);
      state = state.copyWith(localLoading: false, localResult: result);
    } catch (_) {
      state = state.copyWith(localLoading: false, localResult: null);
    }
  }

  Future<void> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || state.isStreaming) return;

    // First user message becomes the session title (anchoredWord)
    final isFirstMessage = !state.messages.any((m) => m.role == 'user');
    if (isFirstMessage) {
      state = state.copyWith(anchoredWord: clean);
      _updateSession();
    }

    final word = state.anchoredWord ?? clean;

    final userMsg = ChatMessage(role: 'user', content: clean, word: word, createdAt: DateTime.now());
    _saveMessage(word, 'user', clean);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isStreaming: true,
    );

    state = state.copyWith(
      messages: [...state.messages, ChatMessage(role: 'assistant', content: '', word: '', createdAt: DateTime.now())],
    );

    try {
      final apiKey = await _config.get('llm_api_key');
      final baseUrl = await _config.get('llm_base_url') ?? ConfigRepository.defaultBaseUrl;
      final model = await _config.get('llm_model') ?? ConfigRepository.defaultModel;

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not configured');
      }

      final history = state.messages
          .where((m) => m.role != 'assistant' || m.content.isNotEmpty)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final stream = _llm.chatStream(
        baseUrl: baseUrl,
        apiKey: apiKey,
        model: model,
        messages: history,
      );

      String fullContent = '';
      await for (final chunk in stream) {
        fullContent += chunk;
        final msgs = [...state.messages];
        msgs[msgs.length - 1] = ChatMessage(
          role: 'assistant',
          content: fullContent,
          word: word,
          createdAt: DateTime.now(),
        );
        state = state.copyWith(messages: msgs);
      }

      if (fullContent.isNotEmpty) {
        _saveMessage(word, 'assistant', fullContent);
      }
    } catch (e) {
      final msgs = [...state.messages];
      msgs[msgs.length - 1] = ChatMessage(
        role: 'assistant',
        content: '抱歉，连接 AI 失败：$e\n\n请检查网络或 API 配置。',
        word: word,
        createdAt: DateTime.now(),
      );
      state = state.copyWith(messages: msgs);
    } finally {
      state = state.copyWith(isStreaming: false);
    }
  }

  Future<void> _saveMessage(String word, String role, String content) async {
    try {
      final db = await DatabaseHelper.instance.db;
      await db.insert('word_chat', {
        'word': word,
        'role': role,
        'content': content,
        'session_id': state.currentSessionId,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  void clearLocalResult() {
    state = state.copyWith(clearLocalResult: true);
  }

  void reset() {
    state = const WordChatState();
  }
}
