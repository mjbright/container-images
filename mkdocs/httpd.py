#!/usr/bin/env python3

from http.server import BaseHTTPRequestHandler, HTTPServer
import time
import os
import sys
import socket

serverhost=socket.gethostname()
serverip=socket.gethostbyname(socket.gethostname())

hostName   = "0.0.0.0"
serverPort = 8080

ASCIITEXT=f"static/img/kubernetes_blue.txt"
PNG=f"static/img/kubernetes_blue.png"
IMAGE='UNSET'
HOSTTYPE='UNSET'

def readfile(path):
   return "".join( open(path).readlines() )

class WebServer(BaseHTTPRequestHandler):
    def do_GET(self):
        host = self.headers.get('Host')
        useragent = self.headers.get('User-Agent').lower()
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()

        hosttype=HOSTTYPE
        imageinfo=IMAGE
        networkinfo=f"{serverhost}/{serverip}"

        t=time.strftime('%l:%M%p %Z on %b %d, %Y') 
        #print(f'[{t}] {IMAGE}: Request received for {host}{self.path} from user agent {useragent}\n')
        sys.stderr.write(f'[{t}] [{hosttype} {networkinfo}] {IMAGE}: Request received for {host}{self.path} from user agent {useragent}\n')

        content=""
        if "curl" in useragent or "http" in useragent or "wget" in useragent:
            if self.path != "/1":
                if os.path.isfile(ASCIITEXT):
                    content = readfile(ASCIITEXT)
                else:
                    content = f'[wd={ os.getcwd() }] No such file as { ASCIITEXT } - '
            content+=f"[{hosttype} {networkinfo}] {imageinfo} - Request from { host }\n"
        else:
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

        self.wfile.write(bytes(content, "utf8"))


if __name__ == "__main__":        
    webServer = HTTPServer((hostName, serverPort), WebServer)
    t=time.strftime('%l:%M%p %Z on %b %d, %Y') 
    sys.stderr.write(f"[{t}] [{serverhost}/{serverip}] [wd={ os.getcwd() }]: Server started - listening on http://{hostName}:{serverPort}\n")

    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()

