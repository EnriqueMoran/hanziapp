from flask import Flask, jsonify, g, request
from flask_cors import CORS
import os
import sqlite3

DATABASE = os.environ.get('DB_PATH', 'hanzi.db')

app = Flask(__name__)
CORS(app)

API_TOKEN = os.environ.get('API_TOKEN')


def ensure_tables():
    conn = sqlite3.connect(DATABASE)
    cur = conn.cursor()
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
    conn.commit()
    conn.close()


ensure_tables()


@app.before_request
def authenticate():
    if request.method == 'OPTIONS':
        return
    if API_TOKEN:
        token = request.headers.get('X-API-Token')
        if token != API_TOKEN:
            return jsonify({'error': 'unauthorized'}), 401


def get_db():
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = sqlite3.connect(DATABASE)
        db.row_factory = sqlite3.Row
    return db


@app.teardown_appcontext
def close_connection(exception):
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()


def query_db(query, args=(), one=False):
    cur = get_db().execute(query, args)
    rv = [dict(row) for row in cur.fetchall()]
    cur.close()
    return (rv[0] if rv else None) if one else rv


def execute_db(query, args=()):
    db = get_db()
    cur = db.execute(query, args)
    db.commit()
    cur.close()


@app.route('/batches', methods=['GET', 'POST'])
def batches():
    if request.method == 'GET':
        rows = query_db('SELECT * FROM batches')
        return jsonify(rows)
    else:
        data = request.get_json() or []
        execute_db('DELETE FROM batches')
        for item in data:
            execute_db(
                'INSERT INTO batches (name, characters) VALUES (?, ?)',
                [item.get('name', ''), item.get('characters', '')],
            )
        return jsonify({'status': 'ok'})


@app.route('/groups', methods=['GET', 'POST'])
def groups():
    if request.method == 'GET':
        rows = query_db('SELECT * FROM groups')
        return jsonify(rows)
    else:
        data = request.get_json() or {}
        if isinstance(data, list):
            for item in data:
                execute_db(
                    'INSERT INTO groups (name, characters) VALUES (?, ?)',
                    [item.get('name', ''), item.get('characters', '')],
                )
        else:
            execute_db(
                'INSERT INTO groups (name, characters) VALUES (?, ?)',
                [data.get('name', ''), data.get('characters', '')],
            )
        return jsonify({'status': 'ok'})


@app.route('/characters', methods=['GET', 'POST'])
def characters_route():
    if request.method == 'GET':
        rows = query_db('SELECT * FROM characters')
        return jsonify(rows)
    data = request.get_json() or {}
    execute_db(
        'INSERT INTO characters (character, pinyin, meaning, level, tags, other, examples) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
            data.get('character', ''),
            data.get('pinyin', ''),
            data.get('meaning', ''),
            data.get('level', ''),
            data.get('tags', ''),
            data.get('other', ''),
            data.get('examples', ''),
        ],
    )
    for tag in (data.get('tags', '') or '').split(','):
        tag = tag.strip()
        if tag:
            execute_db('INSERT OR IGNORE INTO tags (name) VALUES (?)', [tag])
    row = query_db('SELECT last_insert_rowid() AS id', one=True)
    return jsonify({'id': row['id']})


@app.route('/characters/<char>')
def get_character(char):
    row = query_db('SELECT * FROM characters WHERE character = ?', [char], one=True)
    if row:
        return jsonify(row)
    return jsonify({'error': 'not found'}), 404


@app.route('/characters/<int:char_id>', methods=['PUT'])
def update_character(char_id):
    data = request.get_json() or {}
    execute_db(
        'UPDATE characters SET character=?, pinyin=?, meaning=?, level=?, tags=?, other=?, examples=? WHERE id=?',
        [
            data.get('character', ''),
            data.get('pinyin', ''),
            data.get('meaning', ''),
            data.get('level', ''),
            data.get('tags', ''),
            data.get('other', ''),
            data.get('examples', ''),
            char_id,
        ],
    )
    for tag in (data.get('tags', '') or '').split(','):
        tag = tag.strip()
        if tag:
            execute_db('INSERT OR IGNORE INTO tags (name) VALUES (?)', [tag])
    return jsonify({'status': 'ok'})


@app.route('/characters/<int:char_id>', methods=['DELETE'])
def delete_character(char_id):
    execute_db('DELETE FROM characters WHERE id=?', [char_id])
    return jsonify({'status': 'ok'})


@app.route('/tags')
def tags():
    rows = query_db('SELECT name FROM tags')
    return jsonify([r['name'] for r in rows])



@app.route('/groups/<int:gid>', methods=['PUT', 'DELETE'])
def update_group(gid):
    if request.method == 'DELETE':
        execute_db('DELETE FROM groups WHERE id=?', [gid])
        return jsonify({'status': 'ok'})
    data = request.get_json() or {}
    execute_db(
        'UPDATE groups SET name=?, characters=? WHERE id=?',
        [data.get('name', ''), data.get('characters', ''), gid],
    )
    return jsonify({'status': 'ok'})


def _setting_key(key):
    # Ensure the settings table exists before querying
    execute_db('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)')
    if request.method == 'GET':
        row = query_db('SELECT value FROM settings WHERE key=?', [key], one=True)
        return jsonify(row or {'value': ''})
    else:
        data = request.get_json() or {}
        execute_db(
            'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)',
            [key, str(data.get('value', ''))],
        )
        return jsonify({'status': 'ok'})


@app.route('/settings/<key>', methods=['GET', 'PUT'])
def setting(key):
    return _setting_key(key)


@app.route('/settings/last_reviewed', methods=['GET', 'PUT'])
def last_reviewed():
    return _setting_key('last_reviewed_character')


if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)
