import 'dart:convert';
import 'word_context.dart';

class Word {
  final int? id;
  final int notebookId;
  final String text;
  final String? phonetic;
  final String? partOfSpeech;
  final List<String> definitions;
  final List<String> examples;
  final List<WordContext> contexts;
  final List<String> tags;
  final String? imagePath;
  final String? sourceUrl;
  final bool isPhrase;
  final bool isNew;
  final int reviewCount;
  final DateTime learnedAt;
  final bool isMastered;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Word({
    this.id,
    required this.notebookId,
    required this.text,
    this.phonetic,
    this.partOfSpeech,
    this.definitions = const [],
    this.examples = const [],
    this.contexts = const [],
    this.tags = const [],
    this.imagePath,
    this.sourceUrl,
    this.isPhrase = false,
    this.isNew = true,
    this.reviewCount = 0,
    required this.learnedAt,
    this.isMastered = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Word copyWith({
    int? id,
    int? notebookId,
    String? text,
    String? phonetic,
    String? partOfSpeech,
    List<String>? definitions,
    List<String>? examples,
    List<WordContext>? contexts,
    List<String>? tags,
    String? imagePath,
    String? sourceUrl,
    bool? isPhrase,
    bool? isNew,
    int? reviewCount,
    DateTime? learnedAt,
    bool? isMastered,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Word(
    id: id ?? this.id,
    notebookId: notebookId ?? this.notebookId,
    text: text ?? this.text,
    phonetic: phonetic ?? this.phonetic,
    partOfSpeech: partOfSpeech ?? this.partOfSpeech,
    definitions: definitions ?? this.definitions,
    examples: examples ?? this.examples,
    contexts: contexts ?? this.contexts,
    tags: tags ?? this.tags,
    imagePath: imagePath ?? this.imagePath,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    isPhrase: isPhrase ?? this.isPhrase,
    isNew: isNew ?? this.isNew,
    reviewCount: reviewCount ?? this.reviewCount,
    learnedAt: learnedAt ?? this.learnedAt,
    isMastered: isMastered ?? this.isMastered,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'notebookId': notebookId,
    'text': text,
    'phonetic': phonetic,
    'partOfSpeech': partOfSpeech,
    'definitions': jsonEncode(definitions),
    'examples': jsonEncode(examples),
    'contexts': jsonEncode(contexts.map((c) => c.toJson()).toList()),
    'tags': jsonEncode(tags),
    'imagePath': imagePath,
    'sourceUrl': sourceUrl,
    'isPhrase': isPhrase ? 1 : 0,
    'isNew': isNew ? 1 : 0,
    'reviewCount': reviewCount,
    'learnedAt': learnedAt.toIso8601String(),
    'isMastered': isMastered ? 1 : 0,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Word.fromMap(Map<String, dynamic> map) {
    final contextsJson = jsonDecode(map['contexts'] as String) as List<dynamic>;
    final definitionsJson = jsonDecode(map['definitions'] as String) as List<dynamic>;
    final examplesJson = jsonDecode(map['examples'] as String) as List<dynamic>;
    final tagsJson = jsonDecode(map['tags'] as String) as List<dynamic>;
    return Word(
      id: map['id'] as int,
      notebookId: map['notebookId'] as int,
      text: map['text'] as String,
      phonetic: map['phonetic'] as String?,
      partOfSpeech: map['partOfSpeech'] as String?,
      definitions: definitionsJson.cast<String>(),
      examples: examplesJson.cast<String>(),
      contexts: contextsJson.map((c) => WordContext.fromJson(c as Map<String, dynamic>)).toList(),
      tags: tagsJson.cast<String>(),
      imagePath: map['imagePath'] as String?,
      sourceUrl: map['sourceUrl'] as String?,
      isPhrase: (map['isPhrase'] as int) == 1,
      isNew: (map['isNew'] as int) == 1,
      reviewCount: map['reviewCount'] as int? ?? 0,
      learnedAt: DateTime.parse(map['learnedAt'] as String),
      isMastered: (map['isMastered'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
