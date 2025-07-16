import json
import sqlite3
import sys

DB_PATH = 'hanzi.db'


def main():
    if len(sys.argv) < 2:
        print("Usage: python export_data.py <json_file> [db_path]")
        sys.exit(1)

    json_path = sys.argv[1]
    db_path = sys.argv[2] if len(sys.argv) > 2 else DB_PATH

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    cur.execute("SELECT character, pinyin, meaning, level, tags, other, examples FROM characters")
    rows = cur.fetchall()

    data = []
    for r in rows:
        item = {
            'character': r['character'],
            'pinyin': r['pinyin'],
            'meaning': r['meaning'],
            'level': r['level'],
            'tags': [t for t in (r['tags'] or '').split(',') if t],
            'other': r['other'],
            'examples': r['examples']
        }
        data.append(item)

    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"Exported {len(data)} characters to '{json_path}'.")


if __name__ == '__main__':
    main()
