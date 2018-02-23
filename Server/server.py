from flask import render_template
from app import app


@app.route("/shy")
def shy_deply():
    data = {}
    data['password'] = "unlockme"
    data['server'] = "10.0.0.1"
    return render_template("shy_script.j2", data=data)

@app.route("/shy/decrypt")
def shy_decrypt():
    data = {}
    data['password'] = "unlockme"
    data['files'] = ["file.txt", "/home/"]
    return render_template("shy_decryptor.j2", data=data)
