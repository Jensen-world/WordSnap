import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/colors.dart';
import '../../data/models/word.dart';
import '../../data/models/word_context.dart';
import '../../data/services/dictionary_result.dart';
import '../../data/services/llm_dictionary_service.dart';
import '../../data/repositories/config_repository.dart';
import '../settings/api_config_provider.dart';
import '../wordbook/wordbook_provider.dart';
import '../learn/learn_provider.dart';
import '../capture/capture_provider.dart';
import 'word_chat_provider.dart';

class WordChatPage extends ConsumerStatefulWidget {
  final String? initialWord;
  final String? initialMode;

  const WordChatPage({super.key, this.initialWord, this.initialMode});

  @override
  ConsumerState<WordChatPage> createState() => _WordChatPageState();
}

class _WordChatPageState extends ConsumerState<WordChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _drawerType;

  final _apiKeyCtrl = TextEditingController();
  final _baseUrlCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  bool _testing = false;
  bool _obscureApiKey = true;
  int _selectedProviderIdx = -1;

  static const _providers = [
    ('DeepSeek', 'https://api.deepseek.com/v1', 'deepseek-chat'),
    ('智谱 (ChatGLM)', 'https://open.bigmodel.cn/api/paas/v4', 'glm-4-flash'),
    ('火山方舟 (豆包)', 'https://ark.cn-beijing.volces.com/api/v3', 'doubao-pro-32k'),
    ('阿里云百炼 (通义)', 'https://dashscope.aliyuncs.com/compatible-mode/v1', 'qwen-plus'),
    ('自定义', '', ''),
  ];

  bool get _aiAvailable {
    final config = ref.read(apiConfigProvider);
    return config.isConfigured;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(wordChatProvider.notifier).init();
      if (widget.initialWord != null) {
        final notifier = ref.read(wordChatProvider.notifier);
        notifier.setAnchoredWord(widget.initialWord!);
        if (widget.initialMode == 'ai' && _aiAvailable) {
          notifier.setMode(ChatMode.ai);
          notifier.sendMessage('介绍一下「${widget.initialWord}」这个词');
        } else {
          notifier.localLookup(widget.initialWord!);
        }
      }
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _apiKeyCtrl.dispose();
    _baseUrlCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  void _openDrawer(String type) {
    setState(() => _drawerType = type);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _submit() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    final mode = ref.read(wordChatProvider).mode;
    if (mode == ChatMode.local) {
      ref.read(wordChatProvider.notifier).localLookup(text);
    } else {
      ref.read(wordChatProvider.notifier).sendMessage(text);
    }
  }

  void _setMode(ChatMode mode) {
    if (mode == ChatMode.ai && !_aiAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在设置中配置大模型 API 并开启 WordChat')),
      );
      return;
    }
    ref.read(wordChatProvider.notifier).setMode(mode);
  }

  Future<void> _saveWord({String? wordText}) async {
    final state = ref.read(wordChatProvider);
    final result = state.localResult;
    final targetWord = wordText ?? state.anchoredWord;

    // If no direct result, do a lookup for the word
    DictionaryResult? lookupResult = result;
    if (lookupResult == null && targetWord != null && targetWord.isNotEmpty) {
      final service = ref.read(dictionaryServiceProvider);
      lookupResult = await service.lookup(targetWord);
    }
    if (lookupResult == null) return;

    final capture = ref.read(captureStateProvider);
    if (capture.notebooks.isEmpty) {
      await ref.read(captureStateProvider.notifier).loadNotebooks();
    }

    final notebooks = ref.read(captureStateProvider).notebooks;
    if (notebooks.isEmpty) return;

    final notebookId = notebooks.first.id!;
    final notebookName = notebooks.first.name;

    // Check duplicate in same notebook
    final exists = await ref.read(wordRepoProvider).existsByTextInNotebook(lookupResult.word, notebookId);
    if (exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「${lookupResult.word}」已在本单词本中')),
        );
      }
      return;
    }

    final now = DateTime.now();
    final defs = lookupResult.primaryDefinitions;
    final contextType = state.mode == ChatMode.ai ? ContextType.chat : ContextType.manual;
    final word = Word(
      notebookId: notebookId,
      text: lookupResult.word,
      phonetic: lookupResult.phonetic,
      partOfSpeech: lookupResult.meanings.isNotEmpty ? lookupResult.meanings.first.partOfSpeech : null,
      definitions: defs,
      exampleSentence: lookupResult.exampleSentence,
      exampleTranslation: lookupResult.exampleTranslation,
      examples: lookupResult.exampleSentence != null ? [lookupResult.exampleSentence!] : [],
      tags: lookupResult.tag != null ? lookupResult.tag!.split(' ') : [],
      contexts: [WordContext(type: contextType, source: notebookName, timestamp: now)],
      learnedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await ref.read(wordRepoProvider).insert(word);
      ref.read(dataRefreshTrigger.notifier).state++;
      ref.read(learnStateProvider.notifier).load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「${lookupResult.word}」已收录')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wordChatProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.canvasWhite,
      endDrawer: _drawerType == 'settings' ? _buildSettingsDrawer() : _buildHistoryDrawer(state),
      onEndDrawerChanged: (open) {
        if (!open) setState(() => _drawerType = null);
      },
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(state.anchoredWord != null ? '与AI聊${state.anchoredWord}' : 'WordChat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          _AppBarSettingsButton(onTap: () => _openDrawer('settings')),
        ],
      ),
      body: Column(
        children: [
          _buildToolbar(state),
          if (state.mode == ChatMode.local)
            const Padding(
              padding: EdgeInsets.only(top: 6, bottom: 6),
              child: Text(
                '基于ECDICT+Tatoeba离线数据',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
              ),
            ),
          if (state.mode == ChatMode.ai)
            const Padding(
              padding: EdgeInsets.only(top: 6, bottom: 6),
              child: Text(
                '内容由AI生成 仅供参考',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
              ),
            ),
          Expanded(
            child: state.mode == ChatMode.local
                ? _buildLocalMode(state)
                : _buildAiMode(state),
          ),
          if (state.mode == ChatMode.ai && state.anchoredWord != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveWord,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('收录到单词本'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.signalBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                ),
              ),
            ),
          _buildInputBar(state, bottomPad),
        ],
      ),
    );
  }

  Widget _buildToolbar(WordChatState state) {
    final sessionEmpty = state.messages.isEmpty;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolButton(
            icon: LucideIcons.bookMarked,
            label: '本地查词',
            active: state.mode == ChatMode.local,
            onTap: () => _setMode(ChatMode.local),
          ),
          _ToolButton(
            icon: LucideIcons.bot,
            label: 'AI辅助',
            active: state.mode == ChatMode.ai,
            onTap: () => _setMode(ChatMode.ai),
          ),
          _ToolButton(
            icon: LucideIcons.history,
            label: '聊天记录',
            active: false,
            onTap: () => _openDrawer('history'),
          ),
          _ToolButton(
            icon: LucideIcons.messageSquarePlus,
            label: '新对话',
            active: false,
            disabled: sessionEmpty,
            onTap: sessionEmpty ? null : () => ref.read(wordChatProvider.notifier).newSession(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsDrawer() {
    final config = ref.watch(apiConfigProvider);
    final chatEnabled = ref.watch(wordChatEnabledProvider);

    if (_baseUrlCtrl.text.isEmpty && !config.loading) {
      _baseUrlCtrl.text = config.baseUrl;
      _apiKeyCtrl.text = config.apiKey;
      _modelCtrl.text = config.model;
      if (_selectedProviderIdx < 0) {
        _selectedProviderIdx = _matchProvider(config.baseUrl, config.model);
      }
    }

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('AI 配置', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.inkBlack)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF999999)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── WordChat 开关 ──
                  _buildSwitchTile('WordChat', chatEnabled, (v) {
                    ref.read(wordChatEnabledProvider.notifier).toggle();
                  }),
                  const SizedBox(height: 20),
                  // ── LLM 模型配置分区 ──
                  const Text('LLM 模型配置', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.inkBlack)),
                  const SizedBox(height: 4),
                  const Text('兼容 OpenAI 协议，支持多家供应商切换', style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
                  const SizedBox(height: 14),
                  // ── 供应商 ──
                  _buildProviderDropdown(),
                  const SizedBox(height: 14),
                  // ── API 密钥 ──
                  _buildField(
                    'API 密钥',
                    _apiKeyCtrl,
                    hint: 'sk-...',
                    obscure: _obscureApiKey,
                    suffix: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SuffixIcon(
                          icon: _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                          onTap: () => setState(() => _obscureApiKey = !_obscureApiKey),
                        ),
                        const SizedBox(width: 2),
                        _SuffixIcon(asset: 'assets/icons/paste.png', onTap: () => _pasteToField(_apiKeyCtrl)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // ── 接口地址 ──
                  _buildField(
                    '接口地址',
                    _baseUrlCtrl,
                    hint: ConfigRepository.defaultBaseUrl,
                    suffix: _SuffixIcon(asset: 'assets/icons/paste.png', onTap: () => _pasteToField(_baseUrlCtrl)),
                  ),
                  const SizedBox(height: 14),
                  // ── 模型 ──
                  _buildField(
                    '模型',
                    _modelCtrl,
                    hint: ConfigRepository.defaultModel,
                    suffix: _SuffixIcon(asset: 'assets/icons/paste.png', onTap: () => _pasteToField(_modelCtrl)),
                  ),
                  const SizedBox(height: 20),
                  // ── 测试连接 ──
                  FilledButton(
                    onPressed: _testing ? null : _testConnection,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.signalBlue,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: _testing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('测试连接', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _matchProvider(String baseUrl, String model) {
    for (var i = 0; i < _providers.length - 1; i++) {
      final p = _providers[i];
      if (p.$2 == baseUrl && p.$3 == model) return i;
    }
    return _providers.length - 1; // 自定义
  }

  Widget _buildSwitchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.inkBlack)),
        SizedBox(
          height: 28,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.signalBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildProviderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('供应商', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          initialValue: _selectedProviderIdx < 0 ? null : _selectedProviderIdx,
          hint: const Text('请选择供应商', style: TextStyle(fontSize: 13, color: Color(0xFFBBBBBB))),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E2EA)),
            ),
          ),
          items: List.generate(_providers.length, (i) {
            return DropdownMenuItem(value: i, child: Text(_providers[i].$1, style: const TextStyle(fontSize: 14)));
          }),
          onChanged: (i) {
            if (i == null) return;
            _onProviderSelected(i);
          },
        ),
      ],
    );
  }

  void _onProviderSelected(int index) {
    setState(() => _selectedProviderIdx = index);
    final p = _providers[index];
    _baseUrlCtrl.text = p.$2;
    _modelCtrl.text = p.$3;
    // 保存到 config
    final notifier = ref.read(apiConfigProvider.notifier);
    notifier.setBaseUrl(p.$2);
    notifier.setModel(p.$3);
    ref.read(configRepoProvider).set('llm_provider', index.toString());
  }

  void _pasteToField(TextEditingController ctrl) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      ctrl.text = data.text!;
      // 同步保存：追一下当前字段到 config
      if (ctrl == _apiKeyCtrl) ref.read(apiConfigProvider.notifier).setApiKey(data.text!);
      if (ctrl == _baseUrlCtrl) ref.read(apiConfigProvider.notifier).setBaseUrl(data.text!);
      if (ctrl == _modelCtrl) ref.read(apiConfigProvider.notifier).setModel(data.text!);
    }
  }

  Widget _buildField(String label, TextEditingController ctrl, {String? hint, bool obscure = false, Widget? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E2EA)),
            ),
            suffixIcon: suffix,
            suffixIconConstraints: const BoxConstraints(maxHeight: 36),
          ),
          onChanged: (v) {
            if (ctrl == _apiKeyCtrl) ref.read(apiConfigProvider.notifier).setApiKey(v);
            if (ctrl == _baseUrlCtrl) ref.read(apiConfigProvider.notifier).setBaseUrl(v);
            if (ctrl == _modelCtrl) ref.read(apiConfigProvider.notifier).setModel(v);
          },
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    final apiKey = _apiKeyCtrl.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先填写 API Key')),
      );
      return;
    }

    setState(() => _testing = true);

    final llm = LlmDictionaryService();
    final baseUrl = _baseUrlCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    final error = await llm.testConnection(
      baseUrl: baseUrl.isNotEmpty ? baseUrl : ConfigRepository.defaultBaseUrl,
      apiKey: apiKey,
      model: model.isNotEmpty ? model : ConfigRepository.defaultModel,
    );

    if (mounted) {
      setState(() => _testing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error == null ? '连接成功' : '连接失败: $error')),
      );
    }
  }

  Widget _buildHistoryDrawer(WordChatState state) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('聊天记录', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.inkBlack)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF999999)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: state.sessions.isEmpty
                  ? const Center(
                      child: Text('暂无聊天记录', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                    )
                  : ListView.separated(
                      itemCount: state.sessions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                      itemBuilder: (_, i) {
                        final session = state.sessions[i];
                        final isActive = session.id == state.currentSessionId;
                        return _SessionTile(
                          session: session,
                          isActive: isActive,
                          onTap: () {
                            Navigator.of(context).pop();
                            ref.read(wordChatProvider.notifier).switchSession(session.id!);
                          },
                          onDelete: () {
                            ref.read(wordChatProvider.notifier).deleteSession(session.id!);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalMode(WordChatState state) {
    if (state.localLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final result = state.localResult;
    if (result == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_rounded, size: 64, color: AppColors.signalBlue),
              const SizedBox(height: 16),
              Text(
                widget.initialWord != null ? '正在查询「${widget.initialWord}」...' : '输入单词开始本地查词',
                style: const TextStyle(fontSize: 15, color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _LocalResultCard(result: result),
        const SizedBox(height: 16),
        FutureBuilder<bool>(
          future: ref.read(wordRepoProvider).existsByText(result.word),
          builder: (_, snap) {
            final exists = snap.data ?? false;
            if (exists) return const SizedBox.shrink();
            return FilledButton.icon(
              onPressed: _saveWord,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('收录到单词本'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.signalBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAiMode(WordChatState state) {
    if (state.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.bot, size: 64, color: AppColors.signalBlue),
              const SizedBox(height: 16),
              Text(
                state.anchoredWord != null ? '向 AI 提问关于「${state.anchoredWord}」的任何问题' : '输入单词或问题，AI 帮你学习',
                style: const TextStyle(fontSize: 15, color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: state.messages.length,
      itemBuilder: (context, i) {
        final msg = state.messages[i];
        final isUser = msg.role == 'user';
        final isLast = i == state.messages.length - 1;
        return _ChatBubble(
          message: msg,
          isUser: isUser,
          isStreaming: isLast && state.isStreaming && !isUser,
        );
      },
    );
  }

  Widget _buildInputBar(WordChatState state, double bottomPad) {
    final isAiMode = state.mode == ChatMode.ai;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 14 + bottomPad),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAiMode && state.messages.isNotEmpty) ...[
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _QuickChip(label: '造个句子', onTap: () => _sendQuick('请用这个词造一个实用的英文句子，并给出中文翻译')),
                  const SizedBox(width: 6),
                  _QuickChip(label: '近义词辨析', onTap: () => _sendQuick('这个词有哪些近义词？它们之间有什么区别？')),
                  const SizedBox(width: 6),
                  _QuickChip(label: '常见搭配', onTap: () => _sendQuick('这个词有哪些常见搭配和固定短语？')),
                  const SizedBox(width: 6),
                  _QuickChip(label: '语法要点', onTap: () => _sendQuick('使用这个词时有哪些语法要点需要注意？')),
                  const SizedBox(width: 6),
                  _QuickChip(label: '词根词缀', onTap: () => _sendQuick('分析一下这个词的词根词缀和构词法')),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  final word = await context.push<String>('/capture/photo?source=chat');
                  if (word != null && word.isNotEmpty && mounted) {
                    if (state.mode == ChatMode.local) {
                      ref.read(wordChatProvider.notifier).localLookup(word);
                    } else {
                      ref.read(wordChatProvider.notifier).sendMessage(word);
                    }
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F0F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined, size: 20, color: AppColors.signalBlue),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _inputCtrl,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF0F0F5),
                      hintText: state.mode == ChatMode.local ? '输入单词查词...' : '输入单词或问题...',
                      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: state.isStreaming ? null : _submit,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: state.isStreaming ? const Color(0xFFCCCCCC) : AppColors.signalBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    state.isStreaming ? Icons.stop : Icons.arrow_upward,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendQuick(String prompt) {
    ref.read(wordChatProvider.notifier).sendMessage(prompt);
  }
}

class _AppBarSettingsButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AppBarSettingsButton({required this.onTap});

  @override
  State<_AppBarSettingsButton> createState() => _AppBarSettingsButtonState();
}

class _AppBarSettingsButtonState extends State<_AppBarSettingsButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Image.asset(
          'assets/icons/wordchat_config.png',
          width: 22,
          height: 22,
          color: _pressed ? AppColors.signalBlue : const Color(0xFFBBBBBB),
        ),
      ),
    );
  }
}

class _ToolButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool disabled;
  final VoidCallback? onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.active,
    this.disabled = false,
    required this.onTap,
  });

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.disabled;
    final pressed = !disabled && _pressed;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Opacity(
        opacity: disabled ? 0.3 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: pressed || widget.active ? AppColors.signalBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: (pressed || widget.active) ? Colors.white : const Color(0xFF999999),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 10,
                  color: (pressed || widget.active) ? Colors.white : const Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final ChatSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionTile({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = session.anchoredWord ?? '新对话';
    final modeLabel = session.mode == ChatMode.ai ? 'AI' : '本地';
    final dateStr = _formatDate(session.updatedAt);

    return ListTile(
      selected: isActive,
      selectedTileColor: AppColors.signalBlue.withValues(alpha: 0.06),
      onTap: onTap,
      title: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isActive ? AppColors.signalBlue : AppColors.inkBlack),
      ),
      subtitle: Text(
        '$modeLabel · $dateStr · ${session.messageCount} 条消息',
        style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
      ),
      trailing: GestureDetector(
        onTap: onDelete,
        child: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFBBBBBB)),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.month}/${dt.day}';
  }
}

// ── Chat Bubble ──

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;
  final bool isStreaming;

  const _ChatBubble({
    required this.message,
    required this.isUser,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.signalBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.bot, size: 15, color: AppColors.signalBlue),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.signalBlue : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: null,
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5),
                    )
                  : message.content.isEmpty && isStreaming
                      ? const SizedBox(
                          width: 24,
                          height: 16,
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : Text(
                          message.content,
                          style: const TextStyle(fontSize: 14, color: AppColors.inkBlack, height: 1.5),
                        ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Quick Prompt Chip ──

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F5),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
        ),
      ),
    );
  }
}

// ── Local Result Card ──

class _LocalResultCard extends StatelessWidget {
  final dynamic result;

  const _LocalResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E2EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            result.word,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.inkBlack),
          ),
          const SizedBox(height: 6),
          if (result.phonetic != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F5),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('美', style: TextStyle(fontSize: 11, color: AppColors.inkBlack)),
                  const SizedBox(width: 6),
                  Text(result.phonetic!, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ],
              ),
            ),
          const SizedBox(height: 10),
          if (result.meanings.isNotEmpty && result.meanings.first.partOfSpeech.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                result.meanings.first.partOfSpeech,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.signalBlue),
                textAlign: TextAlign.center,
              ),
            ),
          if (result.primaryDefinition.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                result.primaryDefinition,
                style: const TextStyle(fontSize: 14, color: AppColors.inkBlack),
                textAlign: TextAlign.center,
              ),
            ),
          if (result.exampleSentence != null && result.exampleSentence!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF0F0F5))),
              ),
              width: double.infinity,
              child: Text(
                '"${result.exampleSentence}"',
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666), fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
            if (result.exampleTranslation != null && result.exampleTranslation!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  result.exampleTranslation!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'ECDICT + Tatoeba 离线数据',
              style: TextStyle(fontSize: 10, color: Color(0xFFBBBBBB)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuffixIcon extends StatelessWidget {
  final IconData? icon;
  final String? asset;
  final VoidCallback onTap;
  const _SuffixIcon({this.icon, this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: asset != null
            ? Image.asset(asset!, width: 18, height: 18, color: const Color(0xFF999999))
            : Icon(icon, size: 18, color: const Color(0xFF999999)),
      ),
    );
  }
}
