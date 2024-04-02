#!/usr/local/bin/python3
#!/usr/bin/env python3

default_index_template='index.html'
index_title='Welcome'
template_folder='flask.templates'

PORT=9000

from flask import Flask, request, send_from_directory, redirect
from flask import render_template, make_response
from flask import Markup

import socket # for hostname

#import traceback
#import pprint
#pp = pprint.PrettyPrinter(indent=2)
# For json.dumps: prints json more reliably than pprint
#import json

import os,sys
#import datetime, time
#import shutil # To mv files

app = Flask(__name__,
            static_url_path='/static',
            static_folder='static',
            template_folder=template_folder)
''' Setting paths: see https://stackoverflow.com/questions/20646822/how-to-serve-static-files-in-flask
                       https://overiq.com/flask-101/serving-static-files-in-flask/
    app = Flask(__name__,
            static_url_path='',
            static_folder='static',
            template_folder='templates')

   Flask serves up /static by default, alterable via:
       app = Flask(__name__, static_folder="static_dir")

'''

def die(msg):
    print(f"die: {sys.argv[0]} - {msg}")
    sys.exit(1)

@app.after_request
def add_header(response):
    """
    Add headers to both force latest IE rendering engine or Chrome Frame,
    and also to cache the rendered page for 10 minutes.
    """
    response.headers['X-UA-Compatible'] = 'IE=Edge,chrome=1'
    response.headers['Cache-Control'] = 'public, max-age=0'
    return response

def readfile(file):
    f = open( file, 'r')
    lines=f.readlines()
    f.close()
    return lines

def return_template_index(template_file, title):
    app.config['TEMPLATES_AUTO_RELOAD'] = True

    template_file_path=template_folder+'/'+template_file
    if not os.path.exists(template_folder):
        resp_text=f'No such dir <{template_folder}>'
        return return_text(resp_text, code=404)
    print(f'os.path.exists({template_folder})')

    if not os.path.exists(template_file_path):
        resp_text=f'No such file <{template_file_path}>'
        return return_text(resp_text, code=404)
    print(f'os.path.exists({template_file_path})')

    page = render_template(template_file, CLIENT_IP=request.remote_addr, TITLE=title)
    template_text=''.join(readfile(template_file_path))
    resp = make_response(page)
    resp.cache_control.max_age = 1
    return resp

def return_text(resp_text, code=200):
    headers={ 'content-type':'text/plain' }
    response = make_response(resp_text, code)
    response.headers = headers
    return response

@app.route('/')
def root():
    #print(f"\nROOT / - Directory contents={os.listdir('.')}")
    print(f"CLIENT_IP={request.remote_addr}")
    CLIENT_IP=request.remote_addr

    ua=request.headers.get('User-Agent').lower()
    cli_clients=['lynx','curl','wget','links','http','elinks']

    container_image_file='flask.templates/container.image.txt'
    f = open( container_image_file, 'r')
    container_image=f.readline().rstrip()
    f.close()

    host=socket.gethostname()

    resp_text=f'Served from {host} <{container_image}> to {CLIENT_IP}\n'

    for client in cli_clients:
        if client in ua:
            return return_text(resp_text, code=200)

    return return_template_index(default_index_template, index_title )

@app.route('/favicon.ico')
def favicon():
    return send_from_directory('./static', 'favicon.ico')

a=0
while a < len(sys.argv)-1:
    a+=1
    if sys.argv[a] == '-p':
        a+=1
        PORT=int(sys.argv[a])
        continue

    if sys.argv[a] == '-i':
        a+=1
        default_index_url=sys.argv[a]
        continue

    if sys.argv[a] == '-t':
        a+=1
        index_title=sys.argv[a]
        continue

    if sys.argv[a] == '-m':
        a+=1
        mode=sys.argv[a]
        continue

    die(f"Unknown option <{sys.argv[a]}>")

app.jinja_env.auto_reload = True
app.config['TEMPLATES_AUTO_RELOAD'] = True
app.run(host='0.0.0.0', port=PORT, use_reloader=True)

