
PORT=9000
IMG=docker.io/mjbright/k8s-demo:py0

die() { echo "$0: die - $*" >&2; exit 1; }

PRESS() {
    echo; echo "-- $*"
    echo "Press <enter>"
    read DUMMY
    [ "$DUMMY" = "q" ] && exit
    [ "$DUMMY" = "Q" ] && exit

    $*
}

if [ "$1" = "-rm" ]; then
    PRESS "docker rm -f $(docker ps -aq)"
    #PRESS "docker container prune -f"
fi
 
docker ps | grep :${PORT}- && die "Port ${PORT} is already in use"

PRESS docker run -d -p ${PORT}:8080 $IMG

PRESS docker ps

