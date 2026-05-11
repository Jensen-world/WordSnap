import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/config_repository.dart';

final apiConfigProvider = StateNotifierProvider<ApiConfigNotifier, ApiConfig>((ref) {
  return ApiConfigNotifier();
});

class ApiConfig {
  final String baseUrl;
  final String apiKey;
  final String model;
  final bool loading;

  const ApiConfig({
    this.baseUrl = ConfigRepository.defaultBaseUrl,
    this.apiKey = '',
    this.model = ConfigRepository.defaultModel,
    this.loading = true,
  });

  bool get isConfigured => apiKey.isNotEmpty;

  ApiConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? model,
    bool? loading,
  }) => ApiConfig(
    baseUrl: baseUrl ?? this.baseUrl,
    apiKey: apiKey ?? this.apiKey,
    model: model ?? this.model,
    loading: loading ?? this.loading,
  );
}

final wordChatEnabledProvider = StateNotifierProvider<WordChatToggleNotifier, bool>((ref) {
  return WordChatToggleNotifier();
});

class WordChatToggleNotifier extends StateNotifier<bool> {
  final _repo = ConfigRepository();

  WordChatToggleNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final value = await _repo.get('wordchat_enabled');
    state = value != 'false'; // default true (enabled)
  }

  Future<void> toggle() async {
    final newValue = !state;
    await _repo.set('wordchat_enabled', newValue.toString());
    state = newValue;
  }
}

class ApiConfigNotifier extends StateNotifier<ApiConfig> {
  final _repo = ConfigRepository();

  ApiConfigNotifier() : super(const ApiConfig()) {
    _load();
  }

  Future<void> _load() async {
    final baseUrl = await _repo.get('llm_base_url') ?? ConfigRepository.defaultBaseUrl;
    final apiKey = await _repo.get('llm_api_key') ?? '';
    final model = await _repo.get('llm_model') ?? ConfigRepository.defaultModel;
    state = state.copyWith(baseUrl: baseUrl, apiKey: apiKey, model: model, loading: false);
  }

  Future<void> setBaseUrl(String value) async {
    await _repo.set('llm_base_url', value);
    state = state.copyWith(baseUrl: value);
  }

  Future<void> setApiKey(String value) async {
    await _repo.set('llm_api_key', value);
    state = state.copyWith(apiKey: value);
  }

  Future<void> setModel(String value) async {
    await _repo.set('llm_model', value);
    state = state.copyWith(model: value);
  }
}
