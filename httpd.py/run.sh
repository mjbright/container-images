
#BUILDER=podman
BUILDER=docker

#$BUILDER run -p 8080:8080 mjbright/httpd:py
$BUILDER run -d -p 8080:8080 mjbright/httpd:py

