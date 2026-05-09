class DictionaryResult {
  final String word;
  final String? phonetic;
  final String? phoneticUk;
  final String? audioUrl;
  final List<WordMeaning> meanings;
  final String? translation;
  final String? exchange;
  final String? tag;

  const DictionaryResult({
    required this.word,
    this.phonetic,
    this.phoneticUk,
    this.audioUrl,
    this.meanings = const [],
    this.translation,
    this.exchange,
    this.tag,
  });

  factory DictionaryResult.fromEcdict(Map<String, dynamic> row) {
    final definition = row['definition'] as String? ?? '';
    final translation = row['translation'] as String?;
    final pos = row['pos'] as String?;

    final definitions = definition
        .split('\n')
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .map((d) => WordDefinition(definition: d))
        .toList();

    return DictionaryResult(
      word: row['word'] as String,
      phonetic: row['phonetic'] as String?,
      translation: translation,
      exchange: row['exchange'] as String?,
      tag: row['tag'] as String?,
      meanings: pos != null && pos.isNotEmpty
          ? [WordMeaning(partOfSpeech: _expandPos(pos), definitions: definitions)]
          : [WordMeaning(partOfSpeech: '', definitions: definitions)],
    );
  }

  static String _expandPos(String pos) {
    final map = {
      'n': 'noun', 'v': 'verb', 'vi': 'verb', 'vt': 'verb',
      'adj': 'adjective', 'a': 'adjective', 'j': 'adjective',
      'adv': 'adverb', 'r': 'adverb',
      'prep': 'preposition', 'pron': 'pronoun',
      'conj': 'conjunction', 'num': 'numeral',
      'art': 'article', 'interj': 'interjection',
      'u': 'uncountable', 'c': 'countable',
    };
    final parts = pos.split('/');
    return parts.map((p) {
      final code = p.split(':').first.toLowerCase();
      return map[code] ?? code;
    }).join('/');
  }

  factory DictionaryResult.fromJson(Map<String, dynamic> json) {
    final phonetics = (json['phonetics'] as List<dynamic>?) ?? [];
    String? phonetic;
    String? audioUrl;
    for (final p in phonetics) {
      final text = p['text'] as String?;
      final audio = p['audio'] as String?;
      if (text != null && text.isNotEmpty && phonetic == null) phonetic = text;
      if (audio != null && audio.isNotEmpty && audioUrl == null) audioUrl = audio;
    }
    final meanings = (json['meanings'] as List<dynamic>?)
        ?.map((m) => WordMeaning.fromJson(m as Map<String, dynamic>))
        .toList() ?? [];
    return DictionaryResult(
      word: json['word'] as String,
      phonetic: phonetic,
      audioUrl: audioUrl,
      meanings: meanings,
    );
  }
}

class WordMeaning {
  final String partOfSpeech;
  final List<WordDefinition> definitions;

  const WordMeaning({required this.partOfSpeech, this.definitions = const []});

  factory WordMeaning.fromJson(Map<String, dynamic> json) => WordMeaning(
    partOfSpeech: json['partOfSpeech'] as String,
    definitions: (json['definitions'] as List<dynamic>?)
        ?.map((d) => WordDefinition.fromJson(d as Map<String, dynamic>))
        .toList() ?? [],
  );
}

class WordDefinition {
  final String definition;
  final String? example;

  const WordDefinition({required this.definition, this.example});

  factory WordDefinition.fromJson(Map<String, dynamic> json) => WordDefinition(
    definition: json['definition'] as String,
    example: json['example'] as String?,
  );
}
