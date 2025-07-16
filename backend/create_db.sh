#!/bin/sh
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
mkdir -p "$ROOT_DIR/db"
export DB_PATH="$ROOT_DIR/db/hanzi.db"
cd "$SCRIPT_DIR"
python3 init_db.py
