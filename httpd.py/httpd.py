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

def readfile(path):
   return "".join( open(path).readlines() )

class WebServer(BaseHTTPRequestHandler):
    def do_GET(self):
        host = self.headers.get('Host')
        useragent = self.headers.get('User-Agent').lower()
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()

        networkinfo=f"{serverhost}/{serverip}"

        t=time.strftime('%l:%M%p %Z on %b %d, %Y') 
        sys.stderr.write(f'[{t}] [{networkinfo}]: Request received for {host}{self.path} from user agent {useragent}\n')

        content404 = f"""
<html><head>
<title>404 Error - no such file</title>
</head>
<body>
<h1>404 Error: no such url as {self.path}</h1>
</body>
</html>
"""
        content=""
        url_ok=True
        filepath=f"content{self.path}"
        if os.path.isfile(filepath):
            sys.stderr.write(f'OK: {filepath} as is\n')
            content = readfile(filepath)
        elif os.path.isdir(filepath):
            filepath=f"{filepath}/index.html"
            sys.stderr.write(f'{filepath} added /index.html\n')
            if os.path.isfile(filepath):
                sys.stderr.write(f'    OK: {filepath} with /index.html\n')
                content = readfile(filepath)
            else:
                sys.stderr.write(f'    NOT OK: {filepath} with /index.html\n')
                url_ok=False
                content=content404
        else:
            sys.stderr.write(f'    NOT OK: {filepath} neither file or dir\n')
            url_ok=False
            content=content404

        if url_ok:
            served_bytes=len(content)
            sys.stderr.write(f'url OK, file served: {filepath} <{served_bytes} bytes>\n')
        else:
            sys.stderr.write(f'BAD url, attempted to serve non-existent file: {filepath}\n')

        node_name = os.getenv('NODE_NAME', '')
        pod_name = os.getenv('POD_NAME', '')

        if pod_name != '':
            content += f'Served from Pod {pod_name} running on Node {node_name}\n'
        elif node_name != '':
            content += f'Served from Node {node_name}\n'

        sys.stderr.write(f'pod_name={pod_name} node_name={node_name}\n')
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

