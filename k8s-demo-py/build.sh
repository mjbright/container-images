
IMG=mjbright/k8s-demo:py0

BUILDER=docker
#BUILDER=podman

PROMPTS=1

die() { echo "$0: die - $*" >&2; exit 1; }

PRESS() {
    echo; echo "-- $*"
    [ $PROMPTS -eq 0 ] && return

    echo "Press <enter>"
    read DUMMY
    [ "$DUMMY" = "q" ] && exit
    [ "$DUMMY" = "Q" ] && exit
    #$*
}

RUN() {
    PRESS $*
    $*
}

BUILD() {
    IMG=$1; shift

    if [ "$BUILDER" = "docker" ]; then
        RUN docker build -t $IMG . --progress plain
        RUN docker login
        RUN docker push $IMG
    else
        RUN podman build -t $IMG .
        RUN podman login
        RUN podman push $IMG
    fi
}

CREATE_TMP_HTTPD_PY() {
    sed templates/httpd.py.0 \
            -e "s?^ASCIITEXT=.*?ASCIITEXT=\"$ASCIITEXT\"?" \
            -e "s?^PNG=.*?PNG=\"$PNG\"?" \
            > tmp/httpd.py

    ls -al tmp/httpd.py
    [ ! -s tmp/httpd.py ] && die "sed failed when creating tmp/httpd.py"
    #exit

    CMD="diff templates/httpd.py.0 tmp/httpd.py"
    echo; echo "-- $CMD"; $CMD
}

BUILD_ALL() {
    for IDX in {1..6}; do
        IMG=mjbright/k8s-demo:py${IDX}
        echo; echo "==== Building image $IMG"

        case $IDX in
            *) local C="blue"; ASCIITEXT=f"static/img/kubernetes_${C}.txt"; PNG=f"static/img/kubernetes_${C}.png";;
            2) local C="green"; ASCIITEXT=f"static/img/kubernetes_${C}.txt"; PNG=f"static/img/kubernetes_${C}.png";;
            3) local C="red"; ASCIITEXT=f"static/img/kubernetes_${C}.txt"; PNG=f"static/img/kubernetes_${C}.png";;
            4) local C="cyan"; ASCIITEXT=f"static/img/kubernetes_${C}.txt"; PNG=f"static/img/kubernetes_${C}.png";;
            5) local C="yellow"; ASCIITEXT=f"static/img/kubernetes_${C}.txt"; PNG=f"static/img/kubernetes_${C}.png";;
            6) local C="white"; ASCIITEXT=f"static/img/kubernetes_${C}.txt"; PNG=f"static/img/kubernetes_${C}.png";;
        esac

        CREATE_TMP_HTTPD_PY
        echo "-- BUILD $IMG"
        BUILD $IMG
    done
}

if [ "$1" = "-a" ]; then
    PROMPTS=0
    BUILD_ALL
    exit
fi

if [ "$1" = "-p" ]; then
    set -x; docker push $IMG; set +x
    exit
fi


C="blue"; ASCIITEXT=f"static/img/kubernetes_${C}.txt"; PNG=f"static/img/kubernetes_${C}.png"
CREATE_TMP_HTTPD_PY
BUILD $IMG
 
