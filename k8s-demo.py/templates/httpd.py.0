#!/usr/bin/env python3

from http.server import BaseHTTPRequestHandler, HTTPServer
import socket

import time, os, sys
import traceback

serverhost=socket.gethostname()
serverip=socket.gethostbyname(socket.gethostname())

hostName   = "0.0.0.0"
serverPort = 8080

ASCIITEXT="static/img/kubernetes_blue.txt"
PNG="static/img/kubernetes_blue.png"
IMAGE='UNSET'
HOSTTYPE='UNSET'

STARTED=False
LIVE=False
READY=False

def gettimestr():
    #d.strftime("%d/%m/%y")     => '11/03/02'
    #d.strftime("%A %d. %B %Y") => 'Monday 11. March 2002'
    # 2024-April-13 14:46:48
    return time.strftime('%Y-%B-%d %02H:%02M:%0S')

def readfile(path):
   return "".join( open(path).readlines() )

def readfile_lines(path):
   return open(path).readlines()

class WebServer(BaseHTTPRequestHandler):

    def sendResponse(self, code, text, mimetype):
        self.send_response(code)
        self.send_header("Content-type", mimetype)
        self.end_headers()
        self.wfile.write(bytes(text, "utf8"))

    def do_GET(self):
        global START_TIME
        global RESP_200, RESP_503

        host = self.headers.get('Host')
        useragent = self.headers.get('User-Agent').lower()

        # http return codes: https://www.rfc-editor.org/rfc/rfc7231#section-6.6

        now_secs=time.time()
        now=gettimestr()
        #print(f'[{now}] {IMAGE}: Request received for {host}{self.path} from user agent {useragent}\n')
        #sys.stderr.write(f'[{now}] [{hosttype} {networkinfo}] {IMAGE}: Request received for {host}{self.path} from user agent {useragent}\n')

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
200 responses={RESP_200} 503 responses={RESP_503}
'''
            self.sendResponse(200, content, "text/plain")
            return

        if self.path == "/startz":
            RESP_200+=1
            self.sendResponse(200, "OK\n", "text/plain")
            return

        if self.path == "/healthz":
            RESP_200+=1
            self.sendResponse(200, "OK\n", "text/plain")
            return

        if self.path == "/readyz":
            RESP_200+=1
            self.sendResponse(200, "OK\n", "text/plain")
            return

        hosttype=HOSTTYPE
        imageinfo=IMAGE
        networkinfo=f"{serverhost}/{serverip}"

        sys.stderr.write(f'[{now}] [{networkinfo}] {IMAGE}: Request received for {host}{self.path} from user agent {useragent}\n')

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
    a = 1
    config_file="/etc/k8s-demo/config"

    RESP_200=0
    RESP_503=0

    while a < len(sys.argv):
        if sys.argv[a] == "-c":
            a+=1
            config_file=sys.argv[a]

    START_TIME=time.time()

    webServer = HTTPServer((hostName, serverPort), WebServer)
    now=gettimestr()
    sys.stderr.write(f"[{now}] [{serverhost}/{serverip}] [wd={ os.getcwd() }]: Server started - listening on http://{hostName}:{serverPort}\n")

    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()

