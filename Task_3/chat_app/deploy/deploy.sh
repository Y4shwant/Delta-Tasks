#!/bin/bash

set -e  # Exit on error

echo "[+] Pulling latest Docker image..."
docker pull y4shwant/chat-server:latest

echo "[+] Stopping existing containers..."
docker-compose down

echo "[+] Starting fresh deployment..."
docker-compose up -d --build

echo "[✓] Deployment complete. Server is running at port 9000."
