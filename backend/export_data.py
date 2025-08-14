import json
import sqlite3
import sys

import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_DB_PATH = os.path.join(BASE_DIR, '..', 'db', 'hanzi.db')
DB_PATH = os.environ.get('DB_PATH', DEFAULT_DB_PATH)


def main():
    if len(sys.argv) < 2:
        print("Usage: python export_data.py <json_file> [db_path]")
        sys.exit(1)

    json_path = sys.argv[1]
    db_path = sys.argv[2] if len(sys.argv) > 2 else DB_PATH

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    def fetch_all(query):
        cur.execute(query)
        return [dict(r) for r in cur.fetchall()]

    characters = fetch_all('SELECT * FROM characters')
    for rec in characters:
        tags = rec.get('tags', '')
        rec['tags'] = [t for t in tags.split(',') if t]

    data = {
        'characters': characters,
        'batches': fetch_all('SELECT * FROM batches'),
        'groups': fetch_all('SELECT * FROM groups'),
        'tags': [r['name'] for r in fetch_all('SELECT name FROM tags')],
        'settings': {r['key']: r['value'] for r in fetch_all('SELECT * FROM settings')},
    }

    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"Exported database to '{json_path}'.")


if __name__ == '__main__':
    main()
