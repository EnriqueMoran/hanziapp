import json
import sqlite3
import sys

DB_PATH = 'hanzi.db'
JSON_PATH = 'data.json'

def main():
    if len(sys.argv) < 2:
        print("Usage: python import_data.py <json_file> [db_path]")
        sys.exit(1)

    json_path = sys.argv[1]
    db_path = sys.argv[2] if len(sys.argv) > 2 else DB_PATH

    # Connect to your SQLite database
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # Ensure the characters table exists (won't modify it if already correct)
    # Ensure required tables exist
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
    cur.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)')
    cur.execute('CREATE TABLE IF NOT EXISTS batches (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, characters TEXT)')
    cur.execute('CREATE TABLE IF NOT EXISTS groups (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, characters TEXT)')
    cur.execute('CREATE TABLE IF NOT EXISTS tags (name TEXT PRIMARY KEY)')

    # Load the JSON array from file
    with open(json_path, 'r', encoding='utf-8') as f:
        records = json.load(f)

    # Iterate and upsert each record
    for rec in records:
        char      = rec.get('character', '')
        pinyin    = rec.get('pinyin', '')
        meaning   = rec.get('meaning', '')
        level     = rec.get('level', '')
        tags      = ','.join(rec.get('tags', []))        # join list into comma string
        other     = rec.get('other', '')                 # description + examples
        examples  = rec.get('examples', '')              # in your data this may be blank

        cur.execute('''
            INSERT OR REPLACE INTO characters 
              (character, pinyin, meaning, level, tags, other, examples)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (char, pinyin, meaning, level, tags, other, examples))

    # Commit changes and close
    conn.commit()
    conn.close()
    print(f"Upserted {len(records)} characters into '{db_path}'.")

if __name__ == '__main__':
    main()
