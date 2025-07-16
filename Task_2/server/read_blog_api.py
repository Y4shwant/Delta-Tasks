from flask import Flask, Response, abort
import subprocess
import os

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health():
    return "OK", 200

@app.route('/<author>/<blog>', methods=['GET'])
def get_blog(author, blog):
    try:
        cmd = ["sudo", "/usr/local/bin/read_blog.sh", author, blog]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return Response(result.stdout, mimetype='text/plain')
    except subprocess.CalledProcessError as e:
        abort(404, f"Error reading blog: {e.stderr}")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
