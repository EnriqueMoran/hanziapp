from flask import Flask, jsonify, g
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


if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)
