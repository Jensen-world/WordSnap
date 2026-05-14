import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/colors.dart';
import '../../data/services/export_import_service.dart';
import '../../data/services/file_io.dart'
  if (dart.library.js_interop) '../../data/services/file_web.dart';
import '../wordbook/wordbook_provider.dart';
import 'api_config_provider.dart';
import 'api_config_form.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _clipboardEnabled = false;
  bool _exporting = false;
  bool _importing = false;

  Future<void> _handleExport() async {
    setState(() => _exporting = true);
    try {
      final nbRepo = ref.read(notebookRepoProvider);
      final wordRepo = ref.read(wordRepoProvider);
      final service = ExportImportService(nbRepo, wordRepo);
      final jsonStr = await service.exportToJson();

      final totalWords = await wordRepo.getCount();
      final notebooks = await nbRepo.getAll();
      final now = DateTime.now();
      final filename = 'wordsnap_backup_${now.year}-${_pad(now.month)}-${_pad(now.day)}.json';

      final filePath = await writeExportFile(filename, jsonStr);

      if (mounted) {
        setState(() => _exporting = false);
        _showExportDialog(filename, totalWords, notebooks.length, filePath);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _exporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导出失败，请稍后重试')),
        );
      }
    }
  }

  void _showExportDialog(String filename, int wordCount, int notebookCount, String filePath) {
    final dir = filePath.substring(0, filePath.lastIndexOf('/'));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('导出成功', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.inkBlack)),
            const SizedBox(height: 8),
            Text('$wordCount 词 · $notebookCount 个单词本', style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('保存位置', style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
                  const SizedBox(height: 6),
                  Text(dir, style: const TextStyle(fontSize: 12, color: AppColors.inkBlack, fontFamily: 'JetBrains Mono'), maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(filename, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.signalBlue)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _shareFile(ctx, filePath),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E2EA)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: const Text('分享文件', style: TextStyle(color: AppColors.inkBlack)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.signalBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    child: const Text('完成'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareFile(BuildContext ctx, String filePath) async {
    try {
      if (kIsWeb) {
        await Share.share(filePath, subject: 'WordSnap 备份');
      } else {
        final file = XFile(filePath, mimeType: 'application/json');
        await Share.shareXFiles([file]);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('分享失败')),
        );
      }
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  Future<void> _handleImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;

    setState(() => _importing = true);
    try {
      final jsonStr = await readImportFile(result.files.single);
      final nbRepo = ref.read(notebookRepoProvider);
      final wordRepo = ref.read(wordRepoProvider);
      final service = ExportImportService(nbRepo, wordRepo);
      final preview = await service.analyzeJson(jsonStr);

      if (mounted) {
        setState(() => _importing = false);
        _showImportPreviewDialog(service, jsonStr, preview);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _importing = false);
        final message = e is FormatException ? '文件格式不正确，请选择有效的 JSON 备份文件' : '无法读取文件，请稍后重试';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  void _showImportPreviewDialog(ExportImportService service, String jsonStr, ImportPreview preview) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('导入预览', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.inkBlack)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatChip(label: '${preview.totalNotebooks}', suffix: '单词本'),
                const SizedBox(width: 12),
                _StatChip(label: '${preview.totalNewWords}', suffix: '新增词', color: AppColors.mint),
                const SizedBox(width: 12),
                _StatChip(label: '${preview.totalExistingWords}', suffix: '已存在', color: AppColors.amberFlash),
              ],
            ),
            const SizedBox(height: 16),
            ...preview.notebooks.map((nb) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Text('\u{1F4D6} ', style: TextStyle(fontSize: 15)),
                  Expanded(
                    child: Text(
                      nb.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.inkBlack),
                    ),
                  ),
                  Text(
                    '${nb.wordCount}词 · ${nb.exists ? "已存在" : "新增"}',
                    style: TextStyle(fontSize: 12, color: nb.exists ? AppColors.amberFlash : AppColors.mint),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 12),
            const Text(
              '导入规则：同名单词本合并，同词去重',
              style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消', style: TextStyle(color: Color(0xFF999999))),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _performImport(service, jsonStr);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.signalBlue),
            child: const Text('确认导入'),
          ),
        ],
      ),
    );
  }

  Future<void> _performImport(ExportImportService service, String jsonStr) async {
    setState(() => _importing = true);
    try {
      final result = await service.importFromJson(jsonStr);
      if (mounted) {
        setState(() => _importing = false);
        _showImportResultDialog(result['newWords'] ?? 0, result['mergedNotebooks'] ?? 0);
        ref.invalidate(notebookRepoProvider);
        ref.invalidate(wordRepoProvider);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _importing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导入失败，请检查文件后重试')),
        );
      }
    }
  }

  void _showImportResultDialog(int newWords, int mergedNotebooks) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('导入完成', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.inkBlack)),
            const SizedBox(height: 8),
            Text(
              '新增 $newWords 词，合并 $mergedNotebooks 个单词本',
              style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.signalBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                child: const Text('完成'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('设置'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _SectionHeader(title: '数据管理'),
          _SectionCard(children: [
            _ListTile(
              title: '导出数据',
              subtitle: 'JSON 文件，含所有单词本和单词',
              trailing: _exporting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chevron_right, size: 20, color: Color(0xFFBBBBBB)),
              onTap: _exporting ? null : _handleExport,
            ),
            _ListTile(
              title: '导入数据',
              subtitle: '从 JSON 文件恢复，同名去重合并',
              trailing: _importing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chevron_right, size: 20, color: Color(0xFFBBBBBB)),
              onTap: _importing ? null : _handleImport,
            ),
          ]),
          const SizedBox(height: 20),
          _SectionHeader(title: 'AI 配置'),
          _SectionCard(children: [
            _WordChatToggle(),
            _ApiConfigTile(),
          ]),
          const SizedBox(height: 20),
          _SectionHeader(title: '其他'),
          _SectionCard(children: [
            _SwitchTile(
              title: '剪贴板监听',
              value: _clipboardEnabled,
              onChanged: (v) => setState(() => _clipboardEnabled = v),
            ),
            _AboutTile(),
          ]),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
    );
  }
}

class _ListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _ListTile({required this.title, required this.subtitle, required this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: AppColors.inkBlack)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String suffix;
  final Color? color;

  const _StatChip({required this.label, required this.suffix, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.signalBlue;
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: c)),
        Text(suffix, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
      ],
    );
  }
}

class _ApiConfigTile extends ConsumerStatefulWidget {
  const _ApiConfigTile();

  @override
  ConsumerState<_ApiConfigTile> createState() => _ApiConfigTileState();
}

class _ApiConfigTileState extends ConsumerState<_ApiConfigTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(apiConfigProvider);

    if (config.loading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (!_expanded) {
      return GestureDetector(
        onTap: () => setState(() => _expanded = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LLM 模型配置', style: TextStyle(fontSize: 14, color: AppColors.inkBlack)),
                    const SizedBox(height: 2),
                    Text(
                      config.isConfigured ? '已配置 · ${config.model}' : '未配置 · 点击设置',
                      style: TextStyle(fontSize: 12, color: config.isConfigured ? AppColors.mint : const Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: Color(0xFFBBBBBB)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('LLM 模型配置', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.inkBlack)),
              ),
              GestureDetector(
                onTap: () => setState(() => _expanded = false),
                child: const Icon(Icons.check, size: 20, color: AppColors.mint),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('兼容 OpenAI 协议，支持多家供应商切换', style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
          const SizedBox(height: 14),
          const ApiConfigForm(),
        ],
      ),
    );
  }
}

class _WordChatToggle extends ConsumerWidget {
  const _WordChatToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(wordChatEnabledProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('WordChat 功能', style: TextStyle(fontSize: 14, color: AppColors.inkBlack)),
                const SizedBox(height: 2),
                Text(
                  enabled ? '底部 AI 对话入口已开启' : '关闭后隐藏底部对话入口',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (_) => ref.read(wordChatEnabledProvider.notifier).toggle(),
            activeThumbColor: AppColors.signalBlue,
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14, color: AppColors.inkBlack))),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.signalBlue),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _withDividers(children),
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F5)));
      }
    }
    return result;
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/settings/about'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('关于 WordSnap', style: TextStyle(fontSize: 14, color: AppColors.inkBlack)),
                  SizedBox(height: 2),
                  Text('版本、源码与隐私说明', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFFBBBBBB)),
          ],
        ),
      ),
    );
  }
}
