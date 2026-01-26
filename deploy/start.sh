#!/bin/bash
set -e

# Start nginx in background (listens on PORT from Dokku, defaults to 5000)
nginx &

# Start Phoenix on internal port 4000 (nginx proxies /api to here)
export PORT=4000
exec /app/backend/bin/controlcopypasta start
