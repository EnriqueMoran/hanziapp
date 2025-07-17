import json
import sqlite3
import sys

import os

DB_PATH = os.environ.get('DB_PATH', 'hanzi.db')


def ensure_tables(cur):
    cur.execute(
        '''CREATE TABLE IF NOT EXISTS characters (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            character TEXT UNIQUE,
            pinyin TEXT,
            meaning TEXT,
            level TEXT,
            tags TEXT,
            other TEXT,
            examples TEXT
        )'''
    )
    cur.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)')
    cur.execute('CREATE TABLE IF NOT EXISTS batches (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, characters TEXT)')
    cur.execute('CREATE TABLE IF NOT EXISTS groups (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, characters TEXT)')
    cur.execute('CREATE TABLE IF NOT EXISTS tags (name TEXT PRIMARY KEY)')


def main():
    if len(sys.argv) < 2:
        print("Usage: python import_data.py <json_file> [db_path]")
        sys.exit(1)

    json_path = sys.argv[1]
    db_path = sys.argv[2] if len(sys.argv) > 2 else DB_PATH

    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    ensure_tables(cur)

    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    chars = data.get('characters', data if isinstance(data, list) else [])
    for rec in chars:
        cur.execute(
            '''INSERT OR REPLACE INTO characters
               (id, character, pinyin, meaning, level, tags, other, examples)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
            (
                rec.get('id'),
                rec.get('character', ''),
                rec.get('pinyin', ''),
                rec.get('meaning', ''),
                rec.get('level', ''),
                ','.join(rec.get('tags', [])),
                rec.get('other', ''),
                rec.get('examples', ''),
            ),
        )
        for tag in rec.get('tags', []):
            cur.execute('INSERT OR IGNORE INTO tags (name) VALUES (?)', (tag,))

    batches = data.get('batches', [])
    cur.execute('DELETE FROM batches')
    for b in batches:
        cur.execute('INSERT INTO batches (id, name, characters) VALUES (?, ?, ?)',
                    (b.get('id'), b.get('name', ''), b.get('characters', '')))

    groups = data.get('groups', [])
    cur.execute('DELETE FROM groups')
    for g in groups:
        cur.execute('INSERT INTO groups (id, name, characters) VALUES (?, ?, ?)',
                    (g.get('id'), g.get('name', ''), g.get('characters', '')))

    tags = data.get('tags', [])
    for t in tags:
        cur.execute('INSERT OR IGNORE INTO tags (name) VALUES (?)', (t,))

    settings = data.get('settings', {})
    for k, v in settings.items():
        cur.execute('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', (k, str(v)))

    conn.commit()
    conn.close()
    print(f"Imported data from '{json_path}' into '{db_path}'.")


if __name__ == '__main__':
    main()
