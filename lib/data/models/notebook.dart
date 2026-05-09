class Notebook {
  final int? id;
  final String name;
  final bool isDefault;
  final int dailyNewWordLimit;
  final DateTime createdAt;

  const Notebook({
    this.id,
    required this.name,
    this.isDefault = false,
    this.dailyNewWordLimit = 0,
    required this.createdAt,
  });

  Notebook copyWith({
    int? id,
    String? name,
    bool? isDefault,
    int? dailyNewWordLimit,
    DateTime? createdAt,
  }) => Notebook(
    id: id ?? this.id,
    name: name ?? this.name,
    isDefault: isDefault ?? this.isDefault,
    dailyNewWordLimit: dailyNewWordLimit ?? this.dailyNewWordLimit,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'isDefault': isDefault ? 1 : 0,
    'dailyNewWordLimit': dailyNewWordLimit,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Notebook.fromMap(Map<String, dynamic> map) => Notebook(
    id: map['id'] as int,
    name: map['name'] as String,
    isDefault: (map['isDefault'] as int) == 1,
    dailyNewWordLimit: map['dailyNewWordLimit'] as int? ?? 0,
    createdAt: DateTime.parse(map['createdAt'] as String),
  );
}
