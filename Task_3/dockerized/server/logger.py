import os

class ChatLogger:
    def __init__(self):
        base_dir = os.path.dirname(os.path.dirname(__file__))
        self.log_dir = os.path.join(base_dir, "db", "chat_logs")
        if not os.path.exists(self.log_dir):
            os.makedirs(self.log_dir)

    def log(self, room_name, username, message):
        filepath = os.path.join(self.log_dir, f"{room_name}.log")
        with open(filepath, "a") as f:
            f.write(f"{username}: {message}\n")
