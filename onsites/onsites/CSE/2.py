from flask import Flask , jsonify

app=Flask(__name__)
@app.route('/CSE')
def CSE():
    return jsonify({"message": "hello from CSE 2"})
if __name__ == "__main__":
    app.run(host='127.0.0.1', port=5002)