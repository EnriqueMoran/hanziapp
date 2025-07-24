#!/bin/bash
# Start backend (database) and web containers in detached mode.
set -e

docker-compose up -d
