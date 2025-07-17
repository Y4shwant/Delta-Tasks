#!/bin/bash

APP_DIR="/app"
DB_DIR="$APP_DIR/db"
ROOMS_FILE="$DB_DIR/rooms.yaml"
LOG_DIR="$DB_DIR/chat_logs"
SERVER_SCRIPT="$APP_DIR/server/server.py"

echo "[*] Preparing Chat App Server..."

# Ensure DB directory exists
mkdir -p "$DB_DIR"

# Ensure rooms.yaml exists
if [ ! -f "$ROOMS_FILE" ]; then
    echo "[!] rooms.yaml not found. Creating..."
    echo "{}" > "$ROOMS_FILE"
else
    echo "[+] Found existing rooms.yaml"
fi

# Ensure chat_logs directory exists
mkdir -p "$LOG_DIR"

echo "[*] Starting Chat App Server..."
exec python3 "$SERVER_SCRIPT"
