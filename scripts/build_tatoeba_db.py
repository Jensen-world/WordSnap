"""
Build a compact Tatoeba English→Chinese sentence bank for offline use.

Output: assets/tatoeba_slim.db
Schema:  word TEXT, sentence TEXT, translation TEXT, INDEX(word)

Usage:  python scripts/build_tatoeba_db.py

Downloads sentences.csv + links.csv from Tatoeba weekly exports,
filters eng→cmn pairs, indexes by content word, writes SQLite.
"""

import csv
import os
import re
import sqlite3
import sys
import urllib.request

SENTENCES_URL = "https://downloads.tatoeba.org/exports/sentences.csv"
LINKS_URL = "https://downloads.tatoeba.org/exports/links.csv"
OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets")
OUT_DB = os.path.join(OUT_DIR, "tatoeba_slim.db")

# English stop words to skip during indexing
STOP_WORDS = {
    "i", "me", "my", "myself", "we", "our", "ours", "ourselves",
    "you", "your", "yours", "yourself", "yourselves",
    "he", "him", "his", "himself", "she", "her", "hers", "herself",
    "it", "its", "itself", "they", "them", "their", "theirs", "themselves",
    "what", "which", "who", "whom", "this", "that", "these", "those",
    "am", "is", "are", "was", "were", "be", "been", "being",
    "have", "has", "had", "having", "do", "does", "did", "doing",
    "a", "an", "the", "and", "but", "if", "or", "because", "as",
    "until", "while", "of", "at", "by", "for", "with", "about",
    "between", "through", "during", "before", "after", "above", "below",
    "to", "from", "in", "out", "on", "off", "over", "under",
    "again", "further", "then", "once", "here", "there", "when",
    "where", "why", "how", "all", "both", "each", "few", "more",
    "most", "other", "some", "such", "no", "nor", "not", "only",
    "own", "same", "so", "than", "too", "very", "s", "t", "can",
    "will", "just", "don", "should", "now", "d", "ll", "m", "o", "re",
    "ve", "y", "ain", "aren", "couldn", "didn", "doesn", "hadn",
    "hasn", "haven", "isn", "ma", "mightn", "mustn", "needn",
    "shan", "shouldn", "wasn", "weren", "won", "wouldn",
    "also", "even", "still", "already", "yet", "ever", "never",
    "always", "usually", "often", "sometimes", "really", "quite",
    "probably", "certainly", "perhaps", "maybe", "actually",
    "any", "anybody", "anyone", "anything", "anywhere",
    "everybody", "everyone", "everything", "everywhere",
    "somebody", "someone", "something", "somewhere",
    "nobody", "noone", "nothing", "nowhere",
    "let", "get", "got", "go", "went", "gone", "going",
    "say", "said", "see", "saw", "know", "knew",
    "think", "thought", "want", "like", "make", "made",
    "come", "came", "take", "took", "look", "use", "used",
    "tell", "told", "ask", "asked", "try", "tried", "need", "needed",
    "feel", "felt", "seem", "seemed", "show", "showed",
    "put", "give", "gave", "find", "found", "keep", "kept",
    "leave", "left", "call", "called", "set", "turn", "turned",
    "mean", "meant", "work", "worked", "run", "ran", "move", "moved",
    "live", "lived", "believe", "believed", "hold", "held",
    "bring", "brought", "happen", "happened", "write", "wrote", "read",
    "change", "changed", "help", "helped", "play", "played",
    "start", "started", "talk", "talked", "walk", "walked",
    "eat", "ate", "drink", "drank", "sleep", "slept",
    "way", "thing", "things", "time", "day", "man", "woman", "child",
    "world", "life", "hand", "part", "place", "case", "week",
    "company", "system", "program", "question", "work", "government",
    "number", "night", "point", "home", "water", "room", "mother",
    "area", "money", "story", "fact", "month", "lot", "right", "study",
    "book", "eye", "job", "word", "business", "issue", "side", "kind",
    "head", "house", "service", "friend", "father", "power", "hour",
    "game", "line", "end", "member", "law", "car", "city", "community",
    "name", "president", "team", "minute", "idea", "kid", "body",
    "information", "back", "parent", "face", "others", "level",
    "office", "door", "health", "person", "art", "war", "history",
    "party", "result", "morning", "reason", "research", "girl",
    "guy", "moment", "air", "teacher", "force", "education",
}
STOP_WORDS_LOWER = {w.lower() for w in STOP_WORDS}

# Only keep words that are in ECDICT (to avoid indexing noise words)
# We'll load ECDICT word list optionally


def download(url, dest):
    print(f"Downloading {url} ...")
    urllib.request.urlretrieve(url, dest)
    size_mb = os.path.getsize(dest) / 1024 / 1024
    print(f"  -> {dest} ({size_mb:.1f} MB)")


def load_ecd_vocab():
    """Load all words from ECDICT as a set for filtering."""
    ecdict_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "ecdict_slim.db")
    if not os.path.exists(ecdict_path):
        print("ECdict not found, skipping vocabulary filter (all content words will be indexed)")
        return None
    conn = sqlite3.connect(ecdict_path)
    words = set()
    for row in conn.execute("SELECT word FROM stardict"):
        words.add(row[0].lower())
    conn.close()
    print(f"Loaded {len(words)} words from ECDICT vocabulary")
    return words


def extract_words(sentence):
    """Extract significant lowercased words from an English sentence."""
    tokens = re.findall(r"[a-zA-Z]+", sentence.lower())
    return [t for t in tokens if t not in STOP_WORDS_LOWER and len(t) > 1]


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    sentences_path = os.path.join(OUT_DIR, "_sentences.csv")
    links_path = os.path.join(OUT_DIR, "_links.csv")

    # 1. Download
    if not os.path.exists(sentences_path):
        download(SENTENCES_URL, sentences_path)
    else:
        print(f"Using cached {sentences_path}")

    if not os.path.exists(links_path):
        download(LINKS_URL, links_path)
    else:
        print(f"Using cached {links_path}")

    # 2. Load vocabulary filter (optional)
    ecd_vocab = load_ecd_vocab()

    # 3. Parse sentences — only eng and cmn
    print("Parsing sentences...")
    eng = {}  # id -> text
    cmn = {}  # id -> text
    with open(sentences_path, encoding="utf-8", errors="replace") as f:
        reader = csv.reader(f, delimiter="\t")
        for row in reader:
            if len(row) < 3:
                continue
            sid, lang, text = int(row[0]), row[1], row[2]
            if lang == "eng":
                # Skip very long sentences
                if len(text) <= 200:
                    eng[sid] = text
            elif lang == "cmn":
                if len(text) <= 200:
                    cmn[sid] = text
    print(f"  English sentences: {len(eng)}")
    print(f"  Chinese sentences: {len(cmn)}")

    # 4. Parse links — only eng→cmn
    print("Parsing links...")
    pairs = []  # [(eng_id, cmn_id)]
    with open(links_path, encoding="utf-8", errors="replace") as f:
        reader = csv.reader(f, delimiter="\t")
        for row in reader:
            if len(row) < 2:
                continue
            src, dst = int(row[0]), int(row[1])
            if src in eng and dst in cmn:
                pairs.append((src, dst))
    print(f"  eng→cmn pairs: {len(pairs)}")

    # 5. Build database
    print("Building SQLite database...")
    if os.path.exists(OUT_DB):
        os.remove(OUT_DB)
    conn = sqlite3.connect(OUT_DB)
    conn.execute("PRAGMA journal_mode=OFF")
    conn.execute("PRAGMA synchronous=OFF")
    conn.execute("CREATE TABLE tatoeba (word TEXT NOT NULL, sentence TEXT NOT NULL, translation TEXT NOT NULL)")
    conn.execute("CREATE INDEX idx_tatoeba_word ON tatoeba(word)")

    batch = []
    batch_size = 5000
    indexed_pairs = 0
    total_entries = 0

    for eng_id, cmn_id in pairs:
        eng_text = eng[eng_id]
        cmn_text = cmn[cmn_id]

        words = extract_words(eng_text)
        unique_words = set(words)

        if ecd_vocab is not None:
            unique_words = unique_words & ecd_vocab

        if not unique_words:
            continue

        indexed_pairs += 1
        for w in unique_words:
            batch.append((w, eng_text, cmn_text))
            total_entries += 1

        if len(batch) >= batch_size:
            conn.executemany("INSERT INTO tatoeba VALUES (?,?,?)", batch)
            batch.clear()
            if indexed_pairs % 100000 == 0:
                print(f"  processed {indexed_pairs} pairs, {total_entries} index entries")

    if batch:
        conn.executemany("INSERT INTO tatoeba VALUES (?,?,?)", batch)

    conn.commit()
    conn.close()

    size_mb = os.path.getsize(OUT_DB) / 1024 / 1024
    print(f"\nDone: {OUT_DB} ({size_mb:.1f} MB)")
    print(f"  Sentence pairs: {indexed_pairs}")
    print(f"  Index entries: {total_entries}")

    # Clean up downloaded CSVs
    for p in [sentences_path, links_path]:
        if os.path.exists(p):
            os.remove(p)
            print(f"  Removed {p}")


if __name__ == "__main__":
    main()
