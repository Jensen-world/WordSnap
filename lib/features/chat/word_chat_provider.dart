import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/dictionary_result.dart';
import '../../data/services/dictionary_service.dart';
import '../../data/services/llm_dictionary_service.dart';
import '../../data/repositories/config_repository.dart';
import '../../core/database/database_helper.dart';

enum ChatMode { local, ai }

class ChatMessage {
  final int? id;
  final String role;
  final String content;
  final String word;
  final DateTime createdAt;

  const ChatMessage({
    this.id,
    required this.role,
    required this.content,
    required this.word,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'word': word,
    'role': role,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    id: map['id'] as int,
    role: map['role'] as String,
    content: map['content'] as String,
    word: map['word'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
  );
}

class WordChatState {
  final List<ChatMessage> messages;
  final ChatMode mode;
  final bool isStreaming;
  final DictionaryResult? localResult;
  final bool localLoading;
  final String? anchoredWord;

  const WordChatState({
    this.messages = const [],
    this.mode = ChatMode.local,
    this.isStreaming = false,
    this.localResult,
    this.localLoading = false,
    this.anchoredWord,
  });

  WordChatState copyWith({
    List<ChatMessage>? messages,
    ChatMode? mode,
    bool? isStreaming,
    DictionaryResult? localResult,
    bool clearLocalResult = false,
    bool? localLoading,
    String? anchoredWord,
  }) => WordChatState(
    messages: messages ?? this.messages,
    mode: mode ?? this.mode,
    isStreaming: isStreaming ?? this.isStreaming,
    localResult: clearLocalResult ? null : (localResult ?? this.localResult),
    localLoading: localLoading ?? this.localLoading,
    anchoredWord: anchoredWord ?? this.anchoredWord,
  );
}

final wordChatProvider = StateNotifierProvider<WordChatNotifier, WordChatState>((ref) {
  return WordChatNotifier(ref);
});

class WordChatNotifier extends StateNotifier<WordChatState> {
  final Ref _ref;
  final _dictionaryService = DictionaryService();
  final _llm = LlmDictionaryService();
  final _config = ConfigRepository();

  WordChatNotifier(this._ref) : super(const WordChatState());

  void setAnchoredWord(String word) {
    state = state.copyWith(anchoredWord: word);
  }

  void setMode(ChatMode mode) {
    state = state.copyWith(mode: mode);
  }

  Future<void> loadHistory(String word) async {
    try {
      final db = await DatabaseHelper.instance.db;
      final rows = await db.query(
        'word_chat',
        where: 'word = ?',
        whereArgs: [word],
        orderBy: 'createdAt ASC',
        limit: 50,
      );
      final messages = rows.map((r) => ChatMessage.fromMap(r)).toList();
      state = state.copyWith(messages: messages)
          .copyWith(anchoredWord: word);
    } catch (_) {}
  }

  /// Local mode: lookup a word via ECDICT + Tatoeba
  Future<void> localLookup(String word) async {
    final clean = word.trim();
    if (clean.isEmpty) return;
    state = state.copyWith(localLoading: true, clearLocalResult: true);

    // Save user query as message
    _saveMessage(clean, 'user', clean);

    final result = await _dictionaryService.lookup(clean);
    state = state.copyWith(
      localLoading: false,
      localResult: result,
    );
  }

  /// AI mode: send message and stream response
  Future<void> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || state.isStreaming) return;

    final word = state.anchoredWord ?? clean;

    // Add user message
    final userMsg = ChatMessage(role: 'user', content: clean, word: word, createdAt: DateTime.now());
    _saveMessage(word, 'user', clean);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isStreaming: true,
    );

    // Add placeholder for AI response
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

      // Save final AI response
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
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  void clearLocalResult() {
    state = state.copyWith(clearLocalResult: true);
  }
}
