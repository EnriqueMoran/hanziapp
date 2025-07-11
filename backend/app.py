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


@app.route('/characters', methods=['GET', 'POST'])
def list_characters():
    if request.method == 'GET':
        rows = query_db('SELECT * FROM characters')
        return jsonify(rows)
    data = request.get_json(force=True)
    db = get_db()
    db.execute(
        'INSERT INTO characters (character,pinyin,meaning,level,tags,other,examples) '
        'VALUES (?,?,?,?,?,?,?)',
        (
            data.get('character'),
            data.get('pinyin', ''),
            data.get('meaning', ''),
            data.get('level', ''),
            data.get('tags', ''),
            data.get('other', ''),
            data.get('examples', ''),
        ),
    )
    db.commit()
    row = query_db('SELECT * FROM characters WHERE character = ?', [data.get('character')], one=True)
    return jsonify(row), 201


@app.route('/characters/<int:char_id>', methods=['GET', 'PUT', 'DELETE'])
def character_by_id(char_id):
    if request.method == 'GET':
        row = query_db('SELECT * FROM characters WHERE id = ?', [char_id], one=True)
        if row:
            return jsonify(row)
        return jsonify({'error': 'not found'}), 404

    if request.method == 'DELETE':
        db = get_db()
        db.execute('DELETE FROM characters WHERE id = ?', [char_id])
        db.commit()
        return jsonify({'status': 'deleted'})

    # PUT update
    data = request.get_json(force=True)
    db = get_db()
    db.execute(
        'UPDATE characters SET character=?, pinyin=?, meaning=?, level=?, tags=?, other=?, examples=? WHERE id=?',
        (
            data.get('character'),
            data.get('pinyin', ''),
            data.get('meaning', ''),
            data.get('level', ''),
            data.get('tags', ''),
            data.get('other', ''),
            data.get('examples', ''),
            char_id,
        ),
    )
    db.commit()
    row = query_db('SELECT * FROM characters WHERE id = ?', [char_id], one=True)
    return jsonify(row)


@app.route('/last_reviewed', methods=['GET', 'PUT'])
def last_reviewed():
    if request.method == 'GET':
        row = query_db('SELECT * FROM last_reviewed WHERE id = 1', one=True)
        return jsonify(row if row else {})
    data = request.get_json(force=True)
    db = get_db()
    db.execute('UPDATE last_reviewed SET character_id=? WHERE id=1', (data.get('character_id'),))
    db.commit()
    row = query_db('SELECT * FROM last_reviewed WHERE id = 1', one=True)
    return jsonify(row)


@app.route('/batches', methods=['GET', 'POST'])
def batches():
    if request.method == 'GET':
        rows = query_db('SELECT * FROM batches')
        return jsonify(rows)
    data = request.get_json(force=True)
    db = get_db()
    db.execute('INSERT INTO batches (name, characters) VALUES (?,?)', (data.get('name'), data.get('characters', '')))
    db.commit()
    row = query_db('SELECT * FROM batches WHERE id = last_insert_rowid()', one=True)
    return jsonify(row), 201


@app.route('/batches/<int:batch_id>', methods=['PUT', 'DELETE'])
def batch_by_id(batch_id):
    if request.method == 'DELETE':
        db = get_db()
        db.execute('DELETE FROM batches WHERE id=?', (batch_id,))
        db.commit()
        return jsonify({'status': 'deleted'})
    data = request.get_json(force=True)
    db = get_db()
    db.execute('UPDATE batches SET name=?, characters=? WHERE id=?', (data.get('name'), data.get('characters', ''), batch_id))
    db.commit()
    row = query_db('SELECT * FROM batches WHERE id=?', (batch_id,), one=True)
    return jsonify(row)


@app.route('/groups', methods=['GET', 'POST'])
def groups():
    if request.method == 'GET':
        rows = query_db('SELECT * FROM groups')
        return jsonify(rows)
    data = request.get_json(force=True)
    db = get_db()
    db.execute('INSERT INTO groups (name, characters) VALUES (?,?)', (data.get('name'), data.get('characters', '')))
    db.commit()
    row = query_db('SELECT * FROM groups WHERE id = last_insert_rowid()', one=True)
    return jsonify(row), 201


@app.route('/groups/<int:group_id>', methods=['PUT', 'DELETE'])
def group_by_id(group_id):
    if request.method == 'DELETE':
        db = get_db()
        db.execute('DELETE FROM groups WHERE id=?', (group_id,))
        db.commit()
        return jsonify({'status': 'deleted'})
    data = request.get_json(force=True)
    db = get_db()
    db.execute('UPDATE groups SET name=?, characters=? WHERE id=?', (data.get('name'), data.get('characters', ''), group_id))
    db.commit()
    row = query_db('SELECT * FROM groups WHERE id=?', (group_id,), one=True)
    return jsonify(row)


if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)
