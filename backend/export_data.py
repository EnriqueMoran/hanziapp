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

    def fetch_all(query):
        cur.execute(query)
        return [dict(r) for r in cur.fetchall()]

    data = {
        'characters': fetch_all('SELECT * FROM characters'),
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
