import json
import sqlite3



conn = sqlite3.connect('hanzi.db')
cur = conn.cursor()

cur.execute('DROP TABLE IF EXISTS characters')
cur.execute('DROP TABLE IF EXISTS settings')
cur.execute('DROP TABLE IF EXISTS batches')
cur.execute('DROP TABLE IF EXISTS groups')


cur.execute('CREATE TABLE characters (id INTEGER PRIMARY KEY AUTOINCREMENT, character TEXT UNIQUE, pinyin TEXT, meaning TEXT, level TEXT, tags TEXT, other TEXT, examples TEXT)')
cur.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)')
cur.execute('CREATE TABLE batches (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, characters TEXT)')
cur.execute('CREATE TABLE groups (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, characters TEXT)')
with open('data.json', 'r', encoding='utf-8') as f:
    data = json.load(f)
for item in data:
    tags = ','.join(item.get('tags', []))
    cur.execute('INSERT OR REPLACE INTO characters (character,pinyin,meaning,level,tags,other,examples) VALUES (?,?,?,?,?,?,?)', (
        item['character'], item.get('pinyin',''), item.get('meaning',''), item.get('level',''), tags, item.get('other',''), item.get('examples','')))

cur.execute("INSERT OR IGNORE INTO settings (key, value) VALUES ('last_reviewed_character', '')")
conn.commit()
conn.close()
