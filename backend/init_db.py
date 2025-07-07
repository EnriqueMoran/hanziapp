import json
import sqlite3

conn = sqlite3.connect('hanzi.db')
cur = conn.cursor()
cur.execute('CREATE TABLE IF NOT EXISTS characters (id INTEGER PRIMARY KEY AUTOINCREMENT, character TEXT UNIQUE, pinyin TEXT, meaning TEXT, level TEXT, tags TEXT, other TEXT)')
with open('data.json', 'r', encoding='utf-8') as f:
    data = json.load(f)
for item in data:
    tags = ','.join(item.get('tags', []))
    cur.execute('INSERT OR REPLACE INTO characters (character,pinyin,meaning,level,tags,other) VALUES (?,?,?,?,?,?)', (
        item['character'], item.get('pinyin',''), item.get('meaning',''), item.get('level',''), tags, item.get('other','')))
conn.commit()
conn.close()
