FROM python:3.11-slim

WORKDIR /chat_app

COPY server/ ./server/
COPY db/ ./db/
COPY deploy/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh && \
    chmod 755 ./server/server.py && \
    chmod 700 ./server/auth.py ./server/leaderboard.py ./server/rooms.py ./server/logger.py && \
    chmod 700 ./db && \
    chmod 600 ./db/users.db || true && \
    chmod 644 ./db/chat_logs/* || true

ENTRYPOINT ["/entrypoint.sh"]
