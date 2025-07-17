import time

class Leaderboard:
    def __init__(self):
        self.active_users = {}

    def track_user(self, username):
        if username not in self.active_users:
            self.active_users[username] = {
                "message_count": 0,
                "start_time": time.time(),
                "last_active": time.time()
            }

    def update(self, username):
        if username in self.active_users:
            self.active_users[username]["message_count"] += 1
            self.active_users[username]["last_active"] = time.time()

    def disconnect(self, username):
        if username in self.active_users:
            self.active_users[username]["last_active"] = time.time()

    def get_board(self):
        board = "[+] Leaderboard:\n"
        for user, data in self.active_users.items():
            active_time = int((time.time() - data["start_time"]) / 60)
            board += f"- {user}: {data['message_count']} msgs, {active_time} min(s) active\n"
        return board
