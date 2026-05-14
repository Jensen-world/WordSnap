import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../data/services/llm_dictionary_service.dart';
import '../../data/repositories/config_repository.dart';
import 'api_config_provider.dart';

class ApiConfigForm extends ConsumerStatefulWidget {
  const ApiConfigForm({super.key});

  @override
  ConsumerState<ApiConfigForm> createState() => _ApiConfigFormState();
}

class _ApiConfigFormState extends ConsumerState<ApiConfigForm> {
  final _baseUrlCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
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

  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _loadConfig();
      ref.listenManual(apiConfigProvider, (prev, next) {
        if (_loaded) return;
        _loadConfig();
      });
    });
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  void _loadConfig() {
    final config = ref.read(apiConfigProvider);
    if (config.loading) return;
    _loaded = true;
    _baseUrlCtrl.text = config.baseUrl;
    _apiKeyCtrl.text = config.apiKey;
    _modelCtrl.text = config.model;
    _selectedProviderIdx = _matchProvider(config.baseUrl, config.model);
  }

  int _matchProvider(String baseUrl, String model) {
    for (var i = 0; i < _providers.length - 1; i++) {
      final p = _providers[i];
      if (p.$2 == baseUrl && p.$3 == model) return i;
    }
    return _providers.length - 1;
  }

  void _onProviderSelected(int index) {
    setState(() => _selectedProviderIdx = index);
    final p = _providers[index];
    _baseUrlCtrl.text = p.$2;
    _modelCtrl.text = p.$3;
    ref.read(apiConfigProvider.notifier).setBaseUrl(p.$2);
    ref.read(apiConfigProvider.notifier).setModel(p.$3);
    ref.read(configRepoProvider).set('llm_provider', index.toString());
  }

  void _pasteToField(TextEditingController ctrl) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      ctrl.text = data.text!;
      if (ctrl == _apiKeyCtrl) ref.read(apiConfigProvider.notifier).setApiKey(data.text!);
      if (ctrl == _baseUrlCtrl) ref.read(apiConfigProvider.notifier).setBaseUrl(data.text!);
      if (ctrl == _modelCtrl) ref.read(apiConfigProvider.notifier).setModel(data.text!);
    }
  }

  Future<void> _testConnection() async {
    final apiKey = _apiKeyCtrl.text.trim();
    if (apiKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先填写 API 密钥')),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 供应商 ──
        _buildLabel('供应商'),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          initialValue: _selectedProviderIdx < 0 ? null : _selectedProviderIdx,
          hint: const Text('请选择供应商', style: TextStyle(fontSize: 13, color: Color(0xFFBBBBBB))),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF0F0F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
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
        const SizedBox(height: 14),
        // ── API 密钥 ──
        _buildLabel('API 密钥'),
        const SizedBox(height: 6),
        _buildField(
          _apiKeyCtrl,
          hint: '请输入 API 密钥',
          obscure: _obscureApiKey,
          onChanged: (v) => ref.read(apiConfigProvider.notifier).setApiKey(v),
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
        _buildLabel('接口地址'),
        const SizedBox(height: 6),
        _buildField(
          _baseUrlCtrl,
          hint: '请输入接口地址',
          onChanged: (v) => ref.read(apiConfigProvider.notifier).setBaseUrl(v),
          suffix: _SuffixIcon(asset: 'assets/icons/paste.png', onTap: () => _pasteToField(_baseUrlCtrl)),
        ),
        const SizedBox(height: 14),
        // ── 模型 ──
        _buildLabel('模型'),
        const SizedBox(height: 6),
        _buildField(
          _modelCtrl,
          hint: '请输入模型名称',
          onChanged: (v) => ref.read(apiConfigProvider.notifier).setModel(v),
          suffix: _SuffixIcon(asset: 'assets/icons/paste.png', onTap: () => _pasteToField(_modelCtrl)),
        ),
        const SizedBox(height: 20),
        // ── 测试连接 ──
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _testing ? null : _testConnection,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E2EA)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _testing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('测试连接', style: TextStyle(fontSize: 13, color: AppColors.signalBlue)),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF999999)));
  }

  Widget _buildField(TextEditingController ctrl, {bool obscure = false, String hint = '', ValueChanged<String>? onChanged, Widget? suffix}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
        filled: true,
        fillColor: const Color(0xFFF0F0F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffix,
        suffixIconConstraints: const BoxConstraints(maxHeight: 36),
      ),
      style: const TextStyle(fontSize: 14),
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
