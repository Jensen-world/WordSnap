"""Convert existing Tatoeba DB translations from Traditional to Simplified Chinese."""
import sqlite3
import os
import zhconv

DB_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "tatoeba_slim.db")

conn = sqlite3.connect(DB_PATH)
total = conn.execute("SELECT COUNT(*) FROM tatoeba").fetchone()[0]
print(f"Total rows: {total}")

rows = conn.execute("SELECT rowid, translation FROM tatoeba").fetchall()
converted = 0
batch = []
batch_size = 5000

for rowid, trans in rows:
    new_trans = zhconv.convert(trans, 'zh-cn')
    if new_trans != trans:
        batch.append((new_trans, rowid))
        converted += 1
    if len(batch) >= batch_size:
        conn.executemany("UPDATE tatoeba SET translation = ? WHERE rowid = ?", batch)
        conn.commit()
        print(f"  {converted}/{total} converted...")
        batch.clear()

if batch:
    conn.executemany("UPDATE tatoeba SET translation = ? WHERE rowid = ?", batch)
    conn.commit()

conn.close()
print(f"Done: {converted} translations converted")
