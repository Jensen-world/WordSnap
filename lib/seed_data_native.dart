import 'data/models/word.dart';
import 'core/database/database_helper.dart';

Future<void> seedIfEmpty() async {
  final db = await DatabaseHelper.instance.db;
  final count = await db.rawQuery('SELECT COUNT(*) as c FROM words');
  if ((count.first['c'] as int) > 0) return; // already seeded (has words)

  final now = DateTime.now().toIso8601String();

  // Create 2 additional notebooks
  final nb2Id = await db.insert('notebooks', {
    'name': '日常英语',
    'isDefault': 0,
    'dailyNewWordLimit': 8,
    'createdAt': now,
  });
  final nb3Id = await db.insert('notebooks', {
    'name': '商务词汇',
    'isDefault': 0,
    'dailyNewWordLimit': 10,
    'createdAt': now,
  });

  // Seed words
  final words = [
    // 拾词集 (notebookId=1) — 12 words: mix of new, review, mastered
    _w(1, 'ephemeral', '/ɪˈfemərəl/', 'adj.', ['短暂的，转瞬即逝的'], ['Fame is ephemeral — don\'t chase it.'], true, 0, false),
    _w(1, 'serendipity', '/ˌserənˈdɪpəti/', 'n.', ['意外发现珍奇事物的本领', '机缘巧合'], ['Science thrives on serendipity.'], true, 0, false),
    _w(1, 'ubiquitous', '/juːˈbɪkwɪtəs/', 'adj.', ['无处不在的'], ['Smartphones have become ubiquitous.'], false, 3, false),
    _w(1, 'eloquent', '/ˈeləkwənt/', 'adj.', ['雄辩的，有口才的'], ['She gave an eloquent speech.'], false, 5, false),
    _w(1, 'resilient', '/rɪˈzɪliənt/', 'adj.', ['有韧性的，能复原的'], ['Children are remarkably resilient.'], false, 8, false),
    _w(1, 'pragmatic', '/præɡˈmætɪk/', 'adj.', ['务实的，实用的'], ['We need a pragmatic solution.'], false, 0, false),
    _w(1, 'nostalgia', '/nɒˈstældʒə/', 'n.', ['怀旧，乡愁'], ['The song filled her with nostalgia.'], false, 0, false),
    _w(1, 'ambiguous', '/æmˈbɪɡjuəs/', 'adj.', ['模棱两可的'], ['The contract language is ambiguous.'], false, 0, false),
    _w(1, 'meticulous', '/məˈtɪkjʊləs/', 'adj.', ['一丝不苟的'], ['He is meticulous about details.'], true, 0, false),
    _w(1, 'inevitable', '/ɪnˈevɪtəbl/', 'adj.', ['不可避免的'], ['Change is inevitable.'], false, 10, true),
    _w(1, 'diligent', '/ˈdɪlɪdʒənt/', 'adj.', ['勤奋的，刻苦的'], ['She is a diligent student.'], false, 10, true),
    _w(1, 'profound', '/prəˈfaʊnd/', 'adj.', ['深刻的，深远的'], ['The book had a profound impact.'], false, 10, true),

    // 日常英语 (notebookId=nb2Id) — 6 words
    _w(nb2Id, 'procrastinate', '/prəˈkræstɪneɪt/', 'v.', ['拖延，耽搁'], ['Stop procrastinating and start working.'], true, 0, false),
    _w(nb2Id, 'gratitude', '/ˈɡrætɪtjuːd/', 'n.', ['感激之情'], ['Express your gratitude daily.'], true, 0, false),
    _w(nb2Id, 'awkward', '/ˈɔːkwərd/', 'adj.', ['尴尬的，笨拙的'], ['There was an awkward silence.'], false, 2, false),
    _w(nb2Id, 'vivid', '/ˈvɪvɪd/', 'adj.', ['生动的，鲜明的'], ['I have a vivid memory of that day.'], false, 5, false),
    _w(nb2Id, 'subtle', '/ˈsʌtl/', 'adj.', ['微妙的，不易察觉的'], ['There is a subtle difference.'], false, 10, true),
    _w(nb2Id, 'compliment', '/ˈkɒmplɪmənt/', 'n.', ['赞美，恭维'], ['Thanks for the compliment.'], false, 10, true),

    // 商务词汇 (notebookId=nb3Id) — 5 words
    _w(nb3Id, 'leverage', '/ˈlevərɪdʒ/', 'v.', ['利用，发挥杠杆作用'], ['We must leverage our resources.'], true, 0, false),
    _w(nb3Id, 'scalable', '/ˈskeɪləbl/', 'adj.', ['可扩展的'], ['Build a scalable infrastructure.'], true, 0, false),
    _w(nb3Id, 'synergy', '/ˈsɪnədʒi/', 'n.', ['协同效应'], ['The merger created great synergy.'], false, 3, false),
    _w(nb3Id, 'benchmark', '/ˈbentʃmɑːrk/', 'n.', ['基准，标杆'], ['Set a benchmark for quality.'], false, 8, false),
    _w(nb3Id, 'innovative', '/ˈɪnəveɪtɪv/', 'adj.', ['创新的'], ['An innovative approach to marketing.'], false, 10, true),
  ];

  for (final w in words) {
    await db.insert('words', w.toMap());
  }
}

Word _w(
  int notebookId,
  String text,
  String phonetic,
  String pos,
  List<String> defs,
  List<String> examples,
  bool isNew,
  int reviewCount,
  bool isMastered,
) {
  final now = DateTime.now();
  return Word(
    notebookId: notebookId,
    text: text,
    phonetic: phonetic,
    partOfSpeech: pos,
    definitions: defs,
    examples: examples,
    isNew: isNew,
    reviewCount: reviewCount,
    isMastered: isMastered,
    learnedAt: now,
    createdAt: now,
    updatedAt: now,
  );
}
