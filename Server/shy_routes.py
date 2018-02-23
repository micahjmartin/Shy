from flask import render_template
from app import app


@app.route("shy/")
def handout_shy():
    data = {}
    data['password'] = "unlockme"
    data['server'] = "10.0.0.1"
    return render_template("shy.j2", data=data)
