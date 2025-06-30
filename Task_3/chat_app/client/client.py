import socket
import threading
import hashlib

HOST = '127.0.0.1'
PORT = 9000

def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

def authenticate(sock):
    while True:
        print("1. Login\n2. Register")
        choice = input("Choose option (1 or 2): ").strip()

        username = input("Username: ").strip()
        password = input("Password: ").strip()
        hashed = hash_password(password)

        sock.send(f"{choice}:{username}:{hashed}".encode())
        response = sock.recv(1024).decode()

        if response == "AUTH_SUCCESS":
            print(f"[+] Logged in as {username}")
            return username
        else:
            print(f"[!] {response}")

def listen(sock):
    while True:
        try:
            msg = sock.recv(1024).decode()
            if msg:
                print("\n" + msg)
        except:
            print("[!] Connection closed by server")
            break

def main():
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        sock.connect((HOST, PORT))
    except:
        print("[!] Failed to connect to server.")
        return

    username = authenticate(sock)
    threading.Thread(target=listen, args=(sock,), daemon=True).start()

    print("\n[!] Available Commands:")
    print("/create <room_name> <public|private>")
    print("/join <room_name>")
    print("/stats")
    print("/users")
    print("/leaderboard")
    print("/exit")

    while True:
        msg = input()
        if msg.strip() == "/exit":
            sock.close()
            break
        try:
            sock.send(msg.encode())
        except:
            print("[!] Failed to send message.")
            break

if __name__ == "__main__":
    main()
