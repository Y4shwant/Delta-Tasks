from flask import Flask , jsonify

app=Flask(__name__)
@app.route('/MECH')
def MECH():
    return jsonify({"message": "hello from MECH 1"})
if __name__ == "__main__":
    app.run(host='127.0.0.1', port=5007)