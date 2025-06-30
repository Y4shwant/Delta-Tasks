class RoomManager:
    def __init__(self):
        self.rooms = {}  # room_name: { 'visibility': 'public'/'private', 'users': {username: conn}, 'messages': int }

    def create_room(self, room_name, visibility, creator, conn):
        if room_name in self.rooms:
            return False
        self.rooms[room_name] = {
            "visibility": visibility,
            "users": {creator: conn},
            "messages": 0
        }
        return True

    def join_room(self, room_name, username, conn):
        room = self.rooms.get(room_name)
        if not room:
            return False
        room["users"][username] = conn
        return True

    def leave_room(self, room_name, username):
        if room_name and room_name in self.rooms:
            self.rooms[room_name]["users"].pop(username, None)
            if not self.rooms[room_name]["users"]:
                del self.rooms[room_name]  # Cleanup empty room

    def broadcast(self, room_name, message):
        if room_name not in self.rooms:
            return
        room = self.rooms[room_name]
        room["messages"] += 1
        for user_conn in list(room["users"].values()):
            try:
                user_conn.send(message.encode())
            except:
                pass  # Avoid crashing on one broken socket

    def get_stats(self, room_name):
        room = self.rooms.get(room_name)
        if not room:
            return "[!] Room not found"
        return f"[Room: {room_name}] Users: {len(room['users'])} | Messages: {room['messages']}"

    def get_users(self, room_name):
        room = self.rooms.get(room_name)
        if not room:
            return "[!] Room not found"
        return "Active Users: " + ", ".join(room["users"].keys())
