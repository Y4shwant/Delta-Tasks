from flask import Flask, request, jsonify
import jwt

app = Flask(__name__)

SECRET = "secr3t"
ALGORITHM = "HS256"

# Hardcoded credentials
VALID_USERNAME = "guest"
VALID_PASSWORD = "guest"

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")

    if username == VALID_USERNAME and password == VALID_PASSWORD:
        token = jwt.encode({
            "username": username,
            "isAdmin": False,
            "role": "user"
        }, SECRET, algorithm=ALGORITHM)

        if isinstance(token, bytes):
            token = token.decode()

        return jsonify({"token": token})

    return jsonify({"error": "Invalid credentials"}), 401

@app.route('/admin', methods=['GET'])
def admin():
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return jsonify({"error": "Missing or invalid token"}), 401

    token = auth_header.split()[1]

    try:
        payload = jwt.decode(token, SECRET, algorithms=[ALGORITHM])

        if payload.get("isAdmin") is True:
            return jsonify({"flag": "Good job!!! Here's your flag."})
        else:
            return jsonify({"error": "Admin access required"}), 403

    except jwt.InvalidTokenError:
        return jsonify({"error": "Invalid token"}), 400

if __name__ == "__main__":
    app.run(debug=True)
