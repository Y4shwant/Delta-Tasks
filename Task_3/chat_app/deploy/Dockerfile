FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy server code and database
COPY ../server/ ./server/
COPY ../db/ ./db/
COPY ../deploy/entrypoint.sh /entrypoint.sh

# Set permissions securely
RUN chmod +x /entrypoint.sh && \
    chmod 755 ./server/server.py && \
    chmod 700 ./server/auth.py ./server/leaderboard.py ./server/rooms.py ./server/logger.py && \
    chmod 700 ./db && \
    chmod 600 ./db/users.db || true && \
    chmod 644 ./db/chat_logs/* || true

# Set entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
