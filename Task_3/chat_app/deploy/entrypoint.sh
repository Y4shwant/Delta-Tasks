#!/bin/sh

# Secure user DB
chmod 600 /app/db/users.db
chmod 700 /app/db

# Optional: limit other scripts
chmod 700 /app/server/auth.py
chmod 755 /app/server/server.py

exec python3 /app/server/server.py
