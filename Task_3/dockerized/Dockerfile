# Use official Python base image
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Copy requirements if you have them
# RUN pip install -r requirements.txt
# (skip since we use stdlib only)

# Copy application code
COPY . .

# Ensure db directory exists
RUN mkdir -p /app/db/chat_logs

# Set permissions
RUN chmod +x deploy/entrypoint.sh

# Expose server port
EXPOSE 9000

# Entrypoint
ENTRYPOINT ["deploy/entrypoint.sh"]
