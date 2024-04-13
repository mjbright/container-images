
IMG=mjbright/httpd:py

BUILDER=docker
#BUILDER=podman

PRESS() {
    echo; echo "-- $*"
    echo "Press <enter>"
    read DUMMY
    [ "$DUMMY" = "q" ] && exit
    [ "$DUMMY" = "Q" ] && exit

    $*
}

if [ "$1" = "-p" ]; then
    set -x; docker push $IMG; set +x
    exit
fi
 
if [ "$BUILDER" = "docker" ]; then
    PRESS docker build -t $IMG . --progress plain
    PRESS docker login
    PRESS docker push $IMG
else
    PRESS podman build -t $IMG .
    PRESS podman login
    PRESS podman push $IMG
fi

