#!/usr/bin/env python3

from http.server import BaseHTTPRequestHandler, HTTPServer
import socket

# from threading import Timer
import time, os, sys
import threading
import traceback

import signal

TERMINATING=False
terminate_start=0

def signal_handler(sig, frame):
    global TERMINATING, READY

    ''' NOTE: SIGKILL cannot be caught, blocked, or ignored. '''

    #if sig == signal.SIGSTOP:
    #    print('Received SIGSTOP ... finishing processing ongoing requests ...')
    #    READY=False
    #    TERMINATING=True
    #    return

    if sig == signal.SIGTERM:
        terminate_start=time.time()
        sys.stderr.write('Received SIGTERM ... finishing processing ongoing requests ...\n')
        sys.stderr.flush()
        READY=False
        TERMINATING=True

        threading.Thread(target=terminating_thread, args=(terminate_start,)).start()
        return

    if sig == signal.SIGINT:
        sys.stderr.write('Received SIGINT ... finishing processing ongoing requests ...\n')
        sys.stderr.write(f'TERMINATING={TERMINATING}\n')
        sys.stderr.flush()
        READY=False
        if TERMINATING:
            _thread.interrupt_main()
            #os._exit()
            # os.kill(os.getpid(), signal.SIGINT)
            # only exits thread: sys.exit(1)
        terminate_start=time.time()
        TERMINATING=True
        threading.Thread(target=terminating_thread, args=(terminate_start,)).start()
        return
    # catchall:
    print(f'Received signal {sig} - ignoring')
    return

# Sent when Pod is to be deleted: Pod shoud terminate
#signal.signal(signal.SIGSTOP, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT,  signal_handler)

serverhost=socket.gethostname()
serverip=socket.gethostbyname(socket.gethostname())

hostName   = "0.0.0.0"
serverPort = 8080

ASCIITEXT="static/img/kubernetes_blue.txt"
PNG="static/img/kubernetes_blue.png"
IMAGE='UNSET'
HOSTTYPE='UNSET'
if IMAGE != "UNSET":                           HOSTTYPE="Container"
if os.getenv("KUBERNETES_SERVICE_PORT") != "": HOSTTYPE="Pod"

# NOTE: liveness & readiness values are time AFTER startup delay
CONFIG={}

STARTED=False
LIVE=False
READY=False

def gettimestr():
    #d.strftime("%d/%m/%y")     => '11/03/02'
    #d.strftime("%A %d. %B %Y") => 'Monday 11. March 2002'
    # 2024-April-13 14:46:48
    return time.strftime('%Y-%B-%d %02H:%02M:%0S')

def die(msg, code=1):
    sys.stderr.write(f'die: { sys.argv[0] } - { msg }\n')
    sys.stderr.flush()
    sys.exit(code)

def terminating_thread(terminate_start):
  while True:
    terminating_wait = time.time() - terminate_start
    time.sleep(1)
    sys.stderr.write(f"[{terminating_wait:.2f} sec] [SIGTERM received] Terminating tasks...\n")
    sys.stderr.flush()

def check_phase_thread(delay):
  global STARTED, LIVE, READY, CONFIG, START_TIME, TERMINATING
  global hostName, serverPort

  if TERMINATING:
    return

  while True:
    time.sleep(1)
    # sys.stdout.write(".")
    delay = time.time() - START_TIME
    now=gettimestr()

    if not "startup-delay" in CONFIG: CONFIG["startup-delay"]=0
    if not "liveness-delay" in CONFIG: CONFIG["liveness-delay"]=0
    if not "readiness-delay" in CONFIG: CONFIG["readiness-delay"]=0

    if not STARTED:
        #if "startup-delay" in CONFIG and delay > CONFIG["startup-delay"]:
        if delay > CONFIG["startup-delay"]:
            MSG=f"[{now}] Startup phase completed"
            print(MSG)
            sys.stderr.write(f"{MSG}\n")
            sys.stderr.flush()
            STARTED=True

    if not LIVE:
        #if "liveness-delay" in CONFIG and delay > (CONFIG['liveness-delay'] + CONFIG['startup-delay']):
        if delay > (CONFIG['liveness-delay'] + CONFIG['startup-delay']):
            MSG=f"[{now}] Liveness phase completed"
            print(MSG)
            sys.stderr.write(f"{MSG}\n")
            sys.stderr.flush()
            LIVE=True

    if not READY:
        #if "readiness-delay" in CONFIG and delay > (CONFIG['readiness-delay'] + CONFIG['startup-delay']):
        if delay > (CONFIG['readiness-delay'] + CONFIG['startup-delay']):
            MSG=f"[{now}] Readiness phase completed"
            print(MSG)
            sys.stderr.write(f"{MSG}\n")
            sys.stderr.flush()
            READY=True
        sys.stderr.write(f"[{now}] [{serverhost}/{serverip}] [wd={ os.getcwd() }]: Server started - listening on http://{hostName}:{serverPort}\n")
        sys.stderr.flush()

def readfile(path):
   return "".join( open(path).readlines() )

def readfile_lines(path):
   return open(path).readlines()

def read_config(config_file):
    config_lines = readfile_lines(config_file)
    config       = {}

    MSG=f"Reading config from {config_file}"
    print(MSG)
    sys.stderr.write(f"{MSG}\n")
    sys.stderr.flush()

    keys=["startup-delay", "liveness-delay", "readiness-delay"]
    set_default_keys=["startup-delay", "liveness-delay", "readiness-delay"]

    for line in config_lines:
        for key in keys:
            if line.find(f"{key}:") == 0:
                #print(f"line={line}")
                pos = line.find(":")
                value = line[ line.find(":")+1 : ].lstrip().rstrip()
                if "delay" in key:
                    config[key]=int(value)
                else:
                    config[key]=value
                print(f'Setting config[{key}]="{value}"')

    for key in set_default_keys:
        if not key in config: config[key]=0

    #print(f"config={config}")
    return config

class WebServer(BaseHTTPRequestHandler):

    def sendResponse(self, code, text, mimetype):
        self.send_response(code)
        self.send_header("Content-type", mimetype)
        self.end_headers()
        self.wfile.write(bytes(text, "utf8"))

    def do_GET(self):
        global CONFIG, START_TIME
        global RESP_200, RESP_503

        #print(CONFIG)

        host = self.headers.get('Host')
        useragent = self.headers.get('User-Agent').lower()

        # http return codes: https://www.rfc-editor.org/rfc/rfc7231#section-6.6

        now_secs=time.time()
        now=gettimestr()
        #print(f'[{now}] {IMAGE}: Request received for {host}{self.path} from user agent {useragent}\n')
        #sys.stderr.write(f'[{now}] [{hosttype} {networkinfo}] {IMAGE}: Request received for {host}{self.path} from user agent {useragent}\n')
        #sys.stderr.flush()

        if self.path == "/metrics":
            metrics='''
# HELP http_requests_total The total number of HTTP requests.
# TYPE http_requests_total counter
http_requests_total{image='''+IMAGE+''',code="200"} '''+str(RESP_200)+'''
http_requests_total{image='''+IMAGE+''',code="503"} '''+str(RESP_503)+'\n'
             ## # HELP http_requests_total The total number of HTTP requests.
             ## # TYPE http_requests_total counter
             ## http_requests_total\{image={IMAGE},code="200"\} {RESP_200}
             ## http_requests_total\{image={IMAGE},code="503"\} {RESP_503}
            self.sendResponse(200, metrics, "text/plain")
            return
        
        # # Escaping in label values:
        # msdos_file_access_time_seconds\{version={version}} 
        # 
        # # Minimalistic line:
        # metric_without_timestamp_and_labels 12.47

        if self.path == "/reset":
            self.sendResponse(200, "OK\n", "text/plain")
            sys.exit(1)
            return

        if self.path == "/status":
            #RESP_200+=1
            self.send_response(200)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            content=f'''
Time since start={ now_secs - START_TIME } secs
CONFIG={CONFIG}
200 responses={RESP_200}, 503 responses={RESP_503}
STARTED={STARTED} LIVE={LIVE} READY={READY}
'''

            delay = time.time() - START_TIME
            if not STARTED: content += f'Starting in { CONFIG["startup-delay"]   - delay } secs\n'
            if not LIVE:    content += f'Live     in { CONFIG["liveness-delay"]  - delay } secs\n'
            if not READY:   content += f'Ready    in { CONFIG["readiness-delay"] - delay } secs\n'

            self.sendResponse(200, content, "text/plain")
            return

        if self.path == "/startz":
            #self.wfile.write(bytes("OK", "utf8"))
            if STARTED:
                RESP_200+=1
                self.sendResponse(200, "OK\n", "text/plain")
            else:
                RESP_503+=1
                self.sendResponse(503, "NOT Started\n", "text/plain")
            return

        if self.path == "/healthz":
            if LIVE:
                RESP_200+=1
                self.sendResponse(200, "OK\n", "text/plain")
            else:
                RESP_503+=1
                self.sendResponse(503, "NOT Healthy\n", "text/plain")
            return

        if self.path == "/readyz":
            if READY:
                RESP_200+=1
                self.sendResponse(200, "OK\n", "text/plain")
            else:
                RESP_503+=1
                self.sendResponse(503, "NOT Ready\n", "text/plain")
            return

        if not READY:
            RESP_503+=1
            self.sendResponse(503, "NOT Ready\n", "text/plain")
            return

        hosttype=HOSTTYPE
        imageinfo=IMAGE
        networkinfo=f"{serverhost}/{serverip}"
        sys.stderr.write(f'[{now}] [{networkinfo}] {IMAGE}: Request received for {host}{self.path} from user agent {useragent}\n')
        sys.stderr.flush()

        content=""
        if "curl" in useragent or "http" in useragent or "wget" in useragent:
            RESP_200+=1

            if self.path != "/1":
                if os.path.isfile(ASCIITEXT):
                    content = readfile(ASCIITEXT)
                else:
                    content = f'[wd={ os.getcwd() }] No such file as { ASCIITEXT } - '
            content+=f"[{hosttype} {networkinfo}] {imageinfo} - Request from { host }\n"
            self.sendResponse(200, content, "text/plain")
        else:
            RESP_200+=1

            template_values = {
                'host': host,
                'PNG':  PNG,
                'hosttype': hosttype,
                'imageinfo': imageinfo,
                'networkinfo': networkinfo,
            }
            if os.path.isfile(PNG):
                content = readfile("templates/index.html.tmpl").format(**template_values)
            else:
                content = f'''
<html><head><title>Error</title></head>
<body>
    <p>[wd={ os.getcwd() }] No such file as { ASCIITEXT }</p>
</body></html>
'''
            self.sendResponse(200, content, "text/html")

if __name__ == "__main__":        
    sys.stderr.write(f'{ " ".join( sys.argv ) }\n')
    sys.stderr.flush()
    config_file="/etc/k8s-demo/config"
    CONFIG={}

    RESP_200=0
    RESP_503=0

    a = 1
    if a < len(sys.argv): print(f"Reading { len(sys.argv) - 1 } cli arguments")
    while a < len(sys.argv):
        if sys.argv[a] == "-p" or sys.argv[a] == "--port":
            a+=1
            serverPort=int(sys.argv[a])
        if sys.argv[a] == "-c":
            a+=1
            config_file=sys.argv[a]
        if sys.argv[a] == "-sd" or sys.argv[a] == "--startup-delay":
            a+=1;
            CONFIG['startup-delay']=int(sys.argv[a])
        if sys.argv[a] == "-ld" or sys.argv[a] == "--liveness-delay":
            a+=1;
            CONFIG['liveness-delay']=int(sys.argv[a])
        if sys.argv[a] == "-rd" or sys.argv[a] == "--readiness-delay":
            a+=1;
            CONFIG['readiness-delay']=int(sys.argv[a])
        a+=1;
    if len(sys.argv) > 1: print(f"Done reading cli arguments")

    START_TIME=time.time()

    # NOTE: use of , in args, even when a single value:
    threading.Thread(target=check_phase_thread, args=(1.0,)).start()

    # In container:
    if os.path.exists(config_file):
        CONFIG=read_config(config_file)
    
    # TESTING: If not in container:
    elif os.path.exists(f"examples/{config_file}"):
        CONFIG=read_config(f"examples/{config_file}")
        config_file=f"examples/{config_file}"

    #check_config(CONFIG)

    now=gettimestr()
    webServer = HTTPServer((hostName, serverPort), WebServer)

    if             not "startup-delay"   in CONFIG: STARTED=True
    if STARTED and not "liveness-delay"  in CONFIG: LIVE=True
    if LIVE    and not "readiness-delay" in CONFIG: READY=True

    #try:
    sys.stderr.write(f"[{now}] [{serverhost}/{serverip}] [wd={ os.getcwd() }]: Starting server on port { serverPort } ...\n")
    sys.stderr.flush()
    webServer.serve_forever()
    #except KeyboardInterrupt:
    #    pass
    sys.stderr.write(f"[{now}] [{serverhost}/{serverip}] [wd={ os.getcwd() }]: Server exited !!\n")
    sys.stderr.flush()

    webServer.server_close()

