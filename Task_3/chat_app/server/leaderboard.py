import time

class Leaderboard:
    def __init__(self):
        self.data = {}  # username -> {'messages': int, 'join_time': float, 'total_time': float}

    def track_user(self, username):
        if username not in self.data:
            self.data[username] = {
                'messages': 0,
                'join_time': time.time(),
                'total_time': 0.0
            }
        else:
            self.data[username]['join_time'] = time.time()

    def update(self, username):
        if username in self.data:
            self.data[username]['messages'] += 1

    def disconnect(self, username):
        if username in self.data and self.data[username]['join_time']:
            session_time = time.time() - self.data[username]['join_time']
            self.data[username]['total_time'] += session_time
            self.data[username]['join_time'] = None

    def get_board(self):
        sorted_users = sorted(
            self.data.items(),
            key=lambda x: (-x[1]['messages'], -x[1]['total_time'])
        )
        output = ["\n--- Leaderboard ---"]
        for i, (user, stats) in enumerate(sorted_users, 1):
            time_minutes = round(stats['total_time'] / 60, 2)
            output.append(f"{i}. {user} | Msgs: {stats['messages']} | Active: {time_minutes} mins")
        return "\n".join(output)
