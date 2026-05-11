import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../data/models/notebook.dart';
import '../../data/models/word.dart';
import '../settings/api_config_provider.dart';
import '../wordbook/wordbook_provider.dart';
import '../learn/learn_provider.dart';
import '../capture/capture_provider.dart';
import 'word_chat_provider.dart';

class WordChatPage extends ConsumerStatefulWidget {
  final String? initialWord;

  const WordChatPage({super.key, this.initialWord});

  @override
  ConsumerState<WordChatPage> createState() => _WordChatPageState();
}

class _WordChatPageState extends ConsumerState<WordChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  bool get _aiAvailable {
    final config = ref.read(apiConfigProvider);
    return config.isConfigured;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialWord != null) {
      ref.read(wordChatProvider.notifier).setAnchoredWord(widget.initialWord!);
      ref.read(wordChatProvider.notifier).loadHistory(widget.initialWord!);
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
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

  void _onModeChanged(ChatMode mode) {
    if (mode == ChatMode.ai && !_aiAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在设置中配置大模型 API 并开启 WordChat')),
      );
      return;
    }
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

    final now = DateTime.now();
    final defs = result.primaryDefinitions;
    final word = Word(
      notebookId: notebooks.first.id!,
      text: result.word,
      phonetic: result.phonetic,
      partOfSpeech: result.meanings.isNotEmpty ? result.meanings.first.partOfSpeech : null,
      definitions: defs,
      exampleSentence: result.exampleSentence,
      exampleTranslation: result.exampleTranslation,
      examples: result.exampleSentence != null ? [result.exampleSentence!] : [],
      tags: result.tag != null ? result.tag!.split(' ') : [],
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wordChatProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.canvasWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(state.anchoredWord != null ? '与 AI 聊「${state.anchoredWord}」' : 'AI 单词助手'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _ModeToggle(
            current: state.mode,
            aiAvailable: _aiAvailable,
            onChanged: _onModeChanged,
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
              const Icon(Icons.search_rounded, size: 48, color: Color(0xFFDDDDDD)),
              const SizedBox(height: 16),
              Text(
                widget.initialWord != null ? '正在查询「${widget.initialWord}」...' : '输入单词开始本地查词',
                style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                '基于 ECDICT + Tatoeba 离线数据',
                style: TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
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
        FilledButton.icon(
          onPressed: _saveWord,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('收录到单词本'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.signalBlue,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          ),
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
              const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Color(0xFFDDDDDD)),
              const SizedBox(height: 16),
              Text(
                state.anchoredWord != null ? '向 AI 提问关于「${state.anchoredWord}」的任何问题' : '输入单词或问题，AI 帮你学习',
                style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
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
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomPad),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E2EA))),
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
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _inputCtrl,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: state.mode == ChatMode.local ? '输入单词查词...' : '输入单词或问题...',
                      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFFE2E2EA)),
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

// ── Mode Toggle ──

class _ModeToggle extends StatelessWidget {
  final ChatMode current;
  final bool aiAvailable;
  final ValueChanged<ChatMode> onChanged;

  const _ModeToggle({
    required this.current,
    required this.aiAvailable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E2EA))),
      ),
      child: Row(
        children: [
          _Tab(
            label: '本地查词',
            active: current == ChatMode.local,
            onTap: () => onChanged(ChatMode.local),
          ),
          const SizedBox(width: 6),
          _Tab(
            label: 'AI 辅助',
            active: current == ChatMode.ai,
            enabled: aiAvailable,
            onTap: () => onChanged(ChatMode.ai),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.active,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先在设置中配置大模型 API')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.signalBlue : const Color(0xFFF0F0F5),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: active ? Colors.white : (enabled ? const Color(0xFF666666) : const Color(0xFFBBBBBB)),
              ),
            ),
            if (!enabled) ...[
              const SizedBox(width: 4),
              const Icon(Icons.lock, size: 12, color: Color(0xFFBBBBBB)),
            ],
          ],
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              child: const Icon(Icons.auto_awesome, size: 15, color: AppColors.signalBlue),
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
                border: isUser ? null : Border.all(color: const Color(0xFFE2E2EA)),
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
