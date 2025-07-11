import json
import sqlite3

conn = sqlite3.connect('hanzi.db')
cur = conn.cursor()

# Characters table with new 'examples' column
cur.execute(
    'CREATE TABLE IF NOT EXISTS characters ('
    'id INTEGER PRIMARY KEY AUTOINCREMENT, '
    'character TEXT UNIQUE, '
    'pinyin TEXT, '
    'meaning TEXT, '
    'level TEXT, '
    'tags TEXT, '
    'other TEXT, '
    'examples TEXT)'
)

# Table storing the id of the last reviewed character
cur.execute(
    'CREATE TABLE IF NOT EXISTS last_reviewed ('
    'id INTEGER PRIMARY KEY CHECK (id = 1), '
    'character_id INTEGER)'
)
cur.execute('INSERT OR IGNORE INTO last_reviewed (id, character_id) VALUES (1, NULL)')

# Batches and groups tables store comma separated character ids
cur.execute(
    'CREATE TABLE IF NOT EXISTS batches ('
    'id INTEGER PRIMARY KEY AUTOINCREMENT, '
    'name TEXT, '
    'characters TEXT)'
)
cur.execute(
    'CREATE TABLE IF NOT EXISTS groups ('
    'id INTEGER PRIMARY KEY AUTOINCREMENT, '
    'name TEXT, '
    'characters TEXT)'
)
with open('data.json', 'r', encoding='utf-8') as f:
    data = json.load(f)
for item in data:
    tags = ','.join(item.get('tags', []))
    cur.execute(
        'INSERT OR REPLACE INTO characters '
        '(character,pinyin,meaning,level,tags,other,examples) '
        'VALUES (?,?,?,?,?,?,?)',
        (
            item['character'],
            item.get('pinyin', ''),
            item.get('meaning', ''),
            item.get('level', ''),
            tags,
            item.get('other', ''),
            item.get('examples', ''),
        ),
    )
conn.commit()
conn.close()
