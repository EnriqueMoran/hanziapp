import json
import sqlite3
import sys

DB_PATH = 'hanzi.db'


def extract_examples(text: str):
    marker = 'Ejemplos:'
    if marker in text:
        before, after = text.split(marker, 1)
        return before.strip(), after.strip()
    return text.strip(), ''


def main():
    if len(sys.argv) < 2:
        print("Usage: python import_legacy_json.py <json_file> [db_path]")
        sys.exit(1)

    json_path = sys.argv[1]
    db_path = sys.argv[2] if len(sys.argv) > 2 else DB_PATH

    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    cur.execute('''
        CREATE TABLE IF NOT EXISTS characters (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            character TEXT UNIQUE,
            pinyin TEXT,
            meaning TEXT,
            level TEXT,
            tags TEXT,
            other TEXT,
            examples TEXT
        )
    ''')

    records = []
    with open(json_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            data = json.loads(line)
            oid = data.get('_id', {}).get('$oid', '')
            records.append((oid, data))

    # Keep order by OID
    records.sort(key=lambda r: r[0])

    for _, rec in records:
        char = rec.get('character', '')
        pinyin = rec.get('pinyin', '')
        meaning = rec.get('meaning', '')
        level = rec.get('level', '')
        tags = ','.join(rec.get('tags', []))
        other = rec.get('other', '')
        other, examples = extract_examples(other)

        cur.execute(
            '''INSERT OR REPLACE INTO characters
               (character, pinyin, meaning, level, tags, other, examples)
               VALUES (?, ?, ?, ?, ?, ?, ?)''',
            (char, pinyin, meaning, level, tags, other, examples)
        )

    conn.commit()
    conn.close()
    print(f"Imported {len(records)} records from '{json_path}' into '{db_path}'.")


if __name__ == '__main__':
    main()
