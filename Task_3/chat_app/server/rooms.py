import yaml
import random
import os

class RoomManager:
    def __init__(self):
        base_dir = os.path.dirname(os.path.dirname(__file__))  # /home/yashwantb/Delta/Task_3/chat_app
        self.db_dir = os.path.join(base_dir, "db")
        self.rooms_file = os.path.join(self.db_dir, "rooms.yaml")
        self.load_rooms()

    def load_rooms(self):
        if not os.path.exists(self.db_dir):
            os.makedirs(self.db_dir)

        if not os.path.exists(self.rooms_file):
            with open(self.rooms_file, "w") as f:
                yaml.dump({}, f)

        with open(self.rooms_file, "r") as f:
            self.rooms = yaml.safe_load(f) or {}

        for room in self.rooms.values():
            room["users"] = set()

    def save_rooms(self):
        persistent = {
            name: {
                "visibility": data["visibility"],
                "owner": data["owner"],
                "join_code": data["join_code"]
            }
            for name, data in self.rooms.items()
        }
        with open(self.rooms_file, "w") as f:
            yaml.dump(persistent, f)

    def create_room(self, room_name, visibility, owner, conn):
        if room_name in self.rooms:
            return False

        join_code = None
        if visibility == "private":
            join_code = str(random.randint(100000, 999999))

        self.rooms[room_name] = {
            "visibility": visibility,
            "owner": owner,
            "join_code": join_code,
            "users": set([owner])
        }
        self.save_rooms()

        if visibility == "private":
            conn.send(f"[+] Room '{room_name}' created. Share code: {join_code}".encode())
        else:
            conn.send(f"[+] Room '{room_name}' created.".encode())

        return True

    def join_room(self, room_name, username, conn, code=None):
        if room_name not in self.rooms:
            conn.send(f"[!] Room '{room_name}' not found.".encode())
            return False

        room = self.rooms[room_name]

        if room["visibility"] == "private":
            if not code:
                conn.send(b"[!] This is a private room. Enter join code:")
                # Wait for code from client
                code = conn.recv(1024).decode().strip()
            if code != room["join_code"]:
                conn.send(f"[!] Invalid join code for '{room_name}'.".encode())
                return False

        room["users"].add(username)
        conn.send(f"[+] Joined room '{room_name}'.".encode())
        return True
    def leave_room(self, room_name, username):
        if room_name in self.rooms:
            self.rooms[room_name]["users"].discard(username)

    def broadcast(self, room_name, message):
        if room_name in self.rooms:
            for user in self.rooms[room_name]["users"]:
                try:
                    user.send(message.encode())
                except:
                    pass

    def get_users(self, room_name):
        if room_name in self.rooms:
            users = self.rooms[room_name]["users"]
            return "[+] Users in room: " + ", ".join(users)
        return "[!] Room not found."

    def get_stats(self, room_name):
        if room_name in self.rooms:
            user_count = len(self.rooms[room_name]["users"])
            return f"[+] Room '{room_name}' has {user_count} user(s)."
        return "[!] Room not found."
