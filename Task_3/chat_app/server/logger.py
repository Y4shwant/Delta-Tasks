import os
import json
from datetime import datetime

class ChatLogger:
    def __init__(self):
        self.log_dir = os.path.join("..", "db", "chat_logs")
        os.makedirs(self.log_dir, exist_ok=True)

    def log(self, room_name, username, message):
        entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "user": username,
            "message": message
        }
        file_path = os.path.join(self.log_dir, f"{room_name}.log")
        try:
            with open(file_path, "a") as f:
                f.write(json.dumps(entry) + "\n")
        except Exception as e:
            print(f"[!] Failed to log message: {e}")
