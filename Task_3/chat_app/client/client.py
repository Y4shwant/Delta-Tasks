import socket
import threading
import hashlib
import sys

HOST = '127.0.0.1'
PORT = 9000

def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

def authenticate(sock):
    while True:
        print("1. Login\n2. Register")
        choice = input("Choose option (1 or 2): ").strip()

        if choice not in ("1", "2"):
            print("[!] Invalid choice. Please enter 1 or 2.")
            continue

        username = input("Username: ").strip()
        password = input("Password: ").strip()
        hashed = hash_password(password)

        try:
            sock.send(f"{choice}:{username}:{hashed}".encode())
            response = sock.recv(1024).decode()
            if not response:
                print("[!] Server closed connection during authentication.")
                sock.close()
                sys.exit(1)

        except:
            print("[!] Lost connection during authentication.")
            sock.close()
            sys.exit(1)

        if response == "AUTH_SUCCESS":
            print(f"[+] Logged in as {username}")
            return username
        elif response == "AUTH_FAIL":
            print("[!] Authentication failed. Try again.")
        elif response == "USER_EXISTS":
            print("[!] Username already exists. Try logging in.")
        elif response == "INVALID_OPTION":
            print("[!] Invalid option sent to server.")
        else:
            print(f"[!] Unknown server response: {response}")

def listen(sock):
    while True:
        try:
            msg = sock.recv(1024).decode()
            if msg:
                print("\n" + msg)
            else:
                print("[!] Server closed the connection.")
                break
        except:
            print("[!] Lost connection to server.")
            break
    sys.exit(0)

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
        try:
            msg = input()
            if msg.strip() == "/exit":
                sock.send(b"/exit")
                sock.close()
                break
            sock.send(msg.encode())
        except:
            print("[!] Connection lost. Exiting.")
            break

if __name__ == "__main__":
    main()
