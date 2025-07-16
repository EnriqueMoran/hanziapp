#!/bin/sh
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
export DB_PATH="${DB_PATH:-hanzi.db}"
python3 init_db.py
