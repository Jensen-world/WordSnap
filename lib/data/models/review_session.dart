class ReviewSession {
  final int? id;
  final DateTime date;
  final int wordsReviewed;
  final int newWordsLearned;
  final int reviewWordsCorrect;
  final int reviewWordsWrong;
  final bool isCompleted;

  const ReviewSession({
    this.id,
    required this.date,
    this.wordsReviewed = 0,
    this.newWordsLearned = 0,
    this.reviewWordsCorrect = 0,
    this.reviewWordsWrong = 0,
    this.isCompleted = false,
  });

  ReviewSession copyWith({
    int? id,
    DateTime? date,
    int? wordsReviewed,
    int? newWordsLearned,
    int? reviewWordsCorrect,
    int? reviewWordsWrong,
    bool? isCompleted,
  }) => ReviewSession(
    id: id ?? this.id,
    date: date ?? this.date,
    wordsReviewed: wordsReviewed ?? this.wordsReviewed,
    newWordsLearned: newWordsLearned ?? this.newWordsLearned,
    reviewWordsCorrect: reviewWordsCorrect ?? this.reviewWordsCorrect,
    reviewWordsWrong: reviewWordsWrong ?? this.reviewWordsWrong,
    isCompleted: isCompleted ?? this.isCompleted,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'date': date.toIso8601String(),
    'wordsReviewed': wordsReviewed,
    'newWordsLearned': newWordsLearned,
    'reviewWordsCorrect': reviewWordsCorrect,
    'reviewWordsWrong': reviewWordsWrong,
    'isCompleted': isCompleted ? 1 : 0,
  };

  factory ReviewSession.fromMap(Map<String, dynamic> map) => ReviewSession(
    id: map['id'] as int,
    date: DateTime.parse(map['date'] as String),
    wordsReviewed: map['wordsReviewed'] as int? ?? 0,
    newWordsLearned: map['newWordsLearned'] as int? ?? 0,
    reviewWordsCorrect: map['reviewWordsCorrect'] as int? ?? 0,
    reviewWordsWrong: map['reviewWordsWrong'] as int? ?? 0,
    isCompleted: (map['isCompleted'] as int) == 1,
  );
}
