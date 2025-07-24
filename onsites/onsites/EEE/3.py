from flask import Flask , jsonify

app=Flask(__name__)
@app.route('/CSE')
def EEE():
    return jsonify({"message": "hello from EEE 3"})
if __name__ == "__main__":
    app.run(host='127.0.0.1', port=5006)