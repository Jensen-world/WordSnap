import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/colors.dart';
import '../../data/models/word.dart';
import '../../data/models/word_context.dart';
import '../settings/api_config_form.dart';
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

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final notifier = ref.read(wordChatProvider.notifier);
      if (widget.initialWord != null) {
        await notifier.newSession(mode: ChatMode.ai);
        notifier.setAnchoredWord(widget.initialWord!);
        notifier.sendMessage('介绍一下「${widget.initialWord}」这个词');
      } else {
        await notifier.init();
      }
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _openDrawer(String type) {
    setState(() => _drawerType = type);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  String _buildTitle(WordChatState state) {
    final word = state.anchoredWord;
    if (word == null || word.isEmpty) {
      if (state.messages.isEmpty) return 'WordChat';
      return state.mode == ChatMode.ai ? 'AI 对话' : 'WordChat';
    }
    if (state.mode == ChatMode.local) return '查词 · $word';
    return '和AI聊$word';
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
    ref.read(wordChatProvider.notifier).setMode(mode);
  }

  Future<void> _saveWord() async {
    final result = ref.read(wordChatProvider).localResult;
    if (result == null) return;

    final capture = ref.read(captureStateProvider);
    if (capture.notebooks.isEmpty) {
      await ref.read(captureStateProvider.notifier).loadNotebooks();
    }

    final notebooks = ref.read(captureStateProvider).notebooks;
    if (notebooks.isEmpty) return;

    final notebookId = notebooks.first.id!;
    final notebookName = notebooks.first.name;

    final exists = await ref.read(wordRepoProvider).existsByTextInNotebook(result.word, notebookId);
    if (exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「${result.word}」已在本单词本中')),
        );
      }
      return;
    }

    final now = DateTime.now();
    final defs = result.primaryDefinitions;
    final word = Word(
      notebookId: notebookId,
      text: result.word,
      phonetic: result.phonetic,
      partOfSpeech: result.meanings.isNotEmpty ? result.meanings.first.partOfSpeech : null,
      definitions: defs,
      exampleSentence: result.exampleSentence,
      exampleTranslation: result.exampleTranslation,
      examples: result.exampleSentence != null ? [result.exampleSentence!] : [],
      tags: result.tag != null ? result.tag!.split(' ') : [],
      contexts: [WordContext(type: ContextType.manual, source: notebookName, timestamp: now)],
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
          SnackBar(content: Text('「${result.word}」已收录')),
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

  Future<void> _saveWordDirect(String wordText) async {
    if (wordText.isEmpty) return;

    final capture = ref.read(captureStateProvider);
    if (capture.notebooks.isEmpty) {
      await ref.read(captureStateProvider.notifier).loadNotebooks();
    }

    final notebooks = ref.read(captureStateProvider).notebooks;
    if (notebooks.isEmpty) return;

    final notebookId = notebooks.first.id!;
    final notebookName = notebooks.first.name;

    final exists = await ref.read(wordRepoProvider).existsByTextInNotebook(wordText, notebookId);
    if (exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「$wordText」已在本单词本中')),
        );
      }
      return;
    }

    final now = DateTime.now();
    final word = Word(
      notebookId: notebookId,
      text: wordText,
      contexts: [WordContext(type: ContextType.chat, source: notebookName, timestamp: now)],
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
          SnackBar(content: Text('「$wordText」已收录')),
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

  void _onAiBubbleLongPress(ChatMessage msg) {
    final englishRe = RegExp(r'[a-zA-Z]{2,}');
    final words = englishRe.allMatches(msg.content)
        .map((m) => m.group(0)!)
        .toSet()
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final bottomPad = MediaQuery.of(ctx).padding.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (words.isNotEmpty) ...[
                const Text('收录', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: words.map((w) => ChoiceChip(
                    label: Text(w, style: const TextStyle(fontSize: 14)),
                    selected: false,
                    onSelected: (_) {
                      Navigator.pop(ctx);
                      _saveWordDirect(w);
                    },
                    backgroundColor: const Color(0xFFF0F0F5),
                    selectedColor: AppColors.signalBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  )).toList(),
                ),
                const SizedBox(height: 20),
              ],
              ListTile(
                leading: const Icon(Icons.copy, size: 20, color: Color(0xFF999999)),
                title: const Text('复制', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: msg.content));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已复制')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFFF5252)),
                title: const Text('删除', style: TextStyle(fontSize: 14, color: Color(0xFFFF5252))),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(wordChatProvider.notifier).deleteMessage(msg);
                },
              ),
            ],
          ),
        );
      },
    );
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
        title: Text(_buildTitle(state)),
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
    final chatEnabled = ref.watch(wordChatEnabledProvider);

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
                  _buildSwitchTile('WordChat', chatEnabled, (v) {
                    ref.read(wordChatEnabledProvider.notifier).toggle();
                  }),
                  const SizedBox(height: 20),
                  const Text('LLM 模型配置', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.inkBlack)),
                  const SizedBox(height: 4),
                  const Text('兼容 OpenAI 协议，支持多家供应商切换', style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
                  const SizedBox(height: 14),
                  const ApiConfigForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
      final hasLookedUp = state.anchoredWord != null;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasLookedUp ? Icons.search_off_rounded : Icons.search_rounded,
                size: 64,
                color: hasLookedUp ? const Color(0xFFBBBBBB) : AppColors.signalBlue,
              ),
              const SizedBox(height: 16),
              Text(
                hasLookedUp ? '未找到「${state.anchoredWord}」' : '输入单词开始本地查词',
                style: const TextStyle(fontSize: 15, color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),
              if (hasLookedUp) ...[
                const SizedBox(height: 8),
                const Text(
                  '请检查拼写，或切换到 AI 模式获取帮助',
                  style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _LocalResultCard(
          result: result,
          onChat: () => _chatAboutWord(result.word),
        ),
        const SizedBox(height: 16),
        FutureBuilder<bool>(
          future: () async {
            final capture = ref.read(captureStateProvider);
            if (capture.notebooks.isEmpty) {
              await ref.read(captureStateProvider.notifier).loadNotebooks();
            }
            final notebooks = ref.read(captureStateProvider).notebooks;
            if (notebooks.isEmpty) return false;
            return ref.read(wordRepoProvider).existsByText(result.word);
          }(),
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
    final config = ref.read(apiConfigProvider);

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
              if (!config.isConfigured) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _openDrawer('settings'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.amberFlash.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: AppColors.amberFlash),
                        const SizedBox(width: 6),
                        const Text('请先配置 LLM 模型', style: TextStyle(fontSize: 12, color: AppColors.amberFlash)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 12, color: AppColors.amberFlash),
                      ],
                    ),
                  ),
                ),
              ],
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
          onLongPress: () => _onAiBubbleLongPress(msg),
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

  Future<void> _chatAboutWord(String word) async {
    final notifier = ref.read(wordChatProvider.notifier);
    await notifier.newSession(mode: ChatMode.ai);
    notifier.setAnchoredWord(word);
    notifier.sendMessage('介绍一下「$word」这个词');
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
  final VoidCallback? onLongPress;

  const _ChatBubble({
    required this.message,
    required this.isUser,
    this.isStreaming = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Padding(
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

    if (onLongPress != null) {
      return GestureDetector(
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: bubble,
      );
    }
    return bubble;
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
  final VoidCallback? onChat;

  const _LocalResultCard({required this.result, this.onChat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                result.word,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.inkBlack),
              ),
              if (onChat != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onChat,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.signalBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.bot, size: 14, color: AppColors.signalBlue),
                  ),
                ),
              ],
            ],
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
