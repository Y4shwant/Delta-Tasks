import os
import json

USER_DB_PATH = os.path.join("..", "db", "users.db")

class AuthManager:
    def __init__(self):
        os.makedirs(os.path.dirname(USER_DB_PATH), exist_ok=True)
        if not os.path.exists(USER_DB_PATH):
            with open(USER_DB_PATH, "w") as f:
                json.dump({}, f)

    def _load_users(self):
        with open(USER_DB_PATH, "r") as f:
            return json.load(f)

    def _save_users(self, users):
        with open(USER_DB_PATH, "w") as f:
            json.dump(users, f)

    def register(self, username, hashed_pw):
        users = self._load_users()
        if username in users:
            return False  # User exists
        users[username] = hashed_pw
        self._save_users(users)
        return True

    def login(self, username, hashed_pw):
        users = self._load_users()
        return users.get(username) == hashed_pw
