from flask import Flask, jsonify, g, request
from flask_cors import CORS
import sqlite3

DATABASE = 'hanzi.db'

app = Flask(__name__)
CORS(app)


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


@app.route('/characters')
def list_characters():
    rows = query_db('SELECT * FROM characters')
    return jsonify(rows)


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
    return jsonify({'status': 'ok'})


@app.route('/characters/<int:char_id>', methods=['DELETE'])
def delete_character(char_id):
    execute_db('DELETE FROM characters WHERE id=?', [char_id])
    return jsonify({'status': 'ok'})


@app.route('/groups', methods=['GET', 'POST'])
def groups():
    if request.method == 'GET':
        rows = query_db('SELECT * FROM groups')
        return jsonify(rows)
    data = request.get_json() or {}
    execute_db(
        'INSERT INTO groups (name, characters) VALUES (?, ?)',
        [data.get('name', ''), data.get('characters', '')],
    )
    row = query_db('SELECT last_insert_rowid() as id', one=True)
    return jsonify({'id': row['id']})


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


@app.route('/settings/last_reviewed', methods=['GET', 'PUT'])
def last_reviewed():
    if request.method == 'GET':
        row = query_db(
            "SELECT value FROM settings WHERE key='last_reviewed_character'",
            one=True,
        )
        return jsonify(row or {'value': ''})
    else:
        data = request.get_json() or {}
        execute_db(
            "INSERT OR REPLACE INTO settings (key, value) VALUES ('last_reviewed_character', ?)",
            [str(data.get('value', ''))],
        )
        return jsonify({'status': 'ok'})


if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)
