import json
import sqlite3
import os

DB_PATH = os.environ.get('DB_PATH', 'hanzi.db')
JSON_PATH = 'data.json'

def main():
    # Connect to your SQLite database
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    # Ensure the characters table exists (won't modify it if already correct)
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

    # Load the JSON array from file
    with open(JSON_PATH, 'r', encoding='utf-8') as f:
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
    print(f"Upserted {len(records)} characters into '{DB_PATH}'.")

if __name__ == '__main__':
    main()
