enum ContextType { photo, clipboard, manual, web }

class WordContext {
  final ContextType type;
  final String? source;
  final DateTime timestamp;

  const WordContext({
    required this.type,
    this.source,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    if (source != null) 'source': source,
    'timestamp': timestamp.toIso8601String(),
  };

  factory WordContext.fromJson(Map<String, dynamic> json) => WordContext(
    type: ContextType.values.byName(json['type'] as String),
    source: json['source'] as String?,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}
