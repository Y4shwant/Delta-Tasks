import socket
import threading
from auth import AuthManager
from rooms import RoomManager
from leaderboard import Leaderboard
from logger import ChatLogger

HOST = '0.0.0.0'
PORT = 9000

auth = AuthManager()
rooms = RoomManager()
leaderboard = Leaderboard()
logger = ChatLogger()

def handle_client(conn, addr):
    print(f"[+] Connection from {addr}")
    
    try:
        creds = conn.recv(1024).decode().strip()
        if not creds:
            print(f"[-] {addr} disconnected during auth.")
            conn.close()
            return

        parts = creds.split(":")
        if len(parts) != 3:
            conn.send(b"AUTH_FAIL")
            conn.close()
            return

        choice, username, hashed_pw = parts
        success = False

        if choice == "1":
            success = auth.login(username, hashed_pw)
        elif choice == "2":
            success = auth.register(username, hashed_pw)

        if not success:
            conn.send(b"AUTH_FAIL")
            
            return

        conn.send(b"AUTH_SUCCESS")
    except:
        conn.close()
        return

    current_room = None
    leaderboard.track_user(username)

    while True:
        try:
            data = conn.recv(1024).decode().strip()
            if not data:
                break

            if data.startswith("/create"):
                _, room_name, vis = data.split()
                result = rooms.create_room(room_name, vis, username, conn)
                conn.send(f"[+] Room '{room_name}' created.".encode() if result else f"[!] Room '{room_name}' exists.".encode())

            elif data.startswith("/join"):
                _, room_name = data.split()
                result = rooms.join_room(room_name, username, conn)
                if result:
                    current_room = room_name
                    conn.send(f"[+] Joined room '{room_name}'.".encode())
                else:
                    conn.send(f"[!] Room '{room_name}' not found.".encode())

            elif data.startswith("/stats"):
                if current_room:
                    stats = rooms.get_stats(current_room)
                    conn.send(stats.encode())
                else:
                    conn.send(b"[!] Join a room first.")

            elif data.startswith("/users"):
                if current_room:
                    userlist = rooms.get_users(current_room)
                    conn.send(userlist.encode())
                else:
                    conn.send(b"[!] Join a room first.")

            elif data.startswith("/leaderboard"):
                board = leaderboard.get_board()
                conn.send(board.encode())

            else:
                if current_room:
                    msg = f"{username}: {data}"
                    rooms.broadcast(current_room, msg)
                    leaderboard.update(username)
                    logger.log(current_room, username, data)
                else:
                    conn.send(b"[!] Join a room before sending messages.")
        except:
            break

    rooms.leave_room(current_room, username)
    leaderboard.disconnect(username)
    conn.close()
    print(f"[-] {username} disconnected.")

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind((HOST, PORT))
    server.listen()

    print(f"[+] Server listening on {HOST}:{PORT}")

    while True:
        conn, addr = server.accept()
        threading.Thread(target=handle_client, args=(conn, addr), daemon=True).start()

if __name__ == "__main__":
    main()
