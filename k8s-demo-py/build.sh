#!/usr/bin/env bash

IMAGE_BASE=mjbright/k8s-demo:py
IMAGE=${IMAGE_BASE}0

BUILDER=docker
#BUILDER=podman

PROMPTS=1

## Func: ----------------------------------------------------------------------

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
    IMAGE=$1; shift

    if [ "$BUILDER" = "docker" ]; then
        RUN docker build -t $IMAGE . --progress plain
        RUN docker login
        RUN docker push $IMAGE
    else
        RUN podman build -t $IMAGE .
        RUN podman login
        RUN podman push $IMAGE
    fi
}

CREATE_TMP_HTTPD_PY() {
    # set -x
    sed templates/httpd.py.0 \
            -e "s?^ASCIITEXT=.*?ASCIITEXT=\"$ASCIITEXT\"?" \
            -e "s?^PNG=.*?PNG=\"$PNG\"?"                   \
            -e "s?^IMAGE=.*?IMAGE=\"$IMAGE\"?"             \
            > tmp/httpd.py
    # set +x

    chmod +x tmp/httpd.py
    ls   -al tmp/httpd.py
    [ ! -s tmp/httpd.py ] && die "sed failed when creating tmp/httpd.py"
    #exit

    CMD="diff templates/httpd.py.0 tmp/httpd.py"
    echo; echo "-- $CMD"; $CMD
    #read
}

BUILD_0() {
    C="blue"; ASCIITEXT="static/img/kubernetes_${C}.txt"; PNG="static/img/kubernetes_${C}.png"
    CREATE_TMP_HTTPD_PY
    BUILD $IMAGE
    RUN $BUILDER image tag $IMAGE ${IMAGE%0}
    RUN $BUILDER push ${IMAGE%0}
}

BUILD_ALL() {
    local C

    for IDX in {1..6}; do
        IMAGE=mjbright/k8s-demo:py${IDX}
        echo; echo "==== Building image $IMAGE"

        case $IDX in
            2) C="green";  ASCIITEXT="static/img/kubernetes_${C}.txt"; PNG="static/img/kubernetes_${C}.png";;
            3) C="red";    ASCIITEXT="static/img/kubernetes_${C}.txt"; PNG="static/img/kubernetes_${C}.png";;
            4) C="cyan";   ASCIITEXT="static/img/kubernetes_${C}.txt"; PNG="static/img/kubernetes_${C}.png";;
            5) C="yellow"; ASCIITEXT="static/img/kubernetes_${C}.txt"; PNG="static/img/kubernetes_${C}.png";;
            6) C="white";  ASCIITEXT="static/img/kubernetes_${C}.txt"; PNG="static/img/kubernetes_${C}.png";;
            *) C="blue";   ASCIITEXT="static/img/kubernetes_${C}.txt"; PNG="static/img/kubernetes_${C}.png";;
        esac

        #echo "IDX=$IDX IMAGE=$IMAGE C=$C ASCIITEXT=$ASCIITEXT PNG=$PNG"
        CREATE_TMP_HTTPD_PY
        echo "-- BUILD $IMAGE"
        BUILD $IMAGE
    done

    BUILD_0
}

DELETE_ALL_IMAGES() {
    for IDX in {1..6}; do
        IMAGE=${IMAGE_BASE}${IDX}
        RUN $BUILDER image remove $IMAGE
    done

    IMAGE=${IMAGE_BASE}0;   RUN $BUILDER image remove $IMAGE
    IMAGE=${IMAGE_BASE};    RUN $BUILDER image remove $IMAGE

    #[ "$BUILDER" = "docker" ] && $BUILDER image prune
    RUN $BUILDER image prune -f
    RUN $BUILDER image ls
}

## Args: ----------------------------------------------------------------------

while [ $# -ne 0 ]; do
    case $1 in
        -rmi) PROMPTS=0; DELETE_ALL_IMAGES; exit $?;;
        -a)   PROMPTS=0; BUILD_ALL; exit $?;;

        -p)   set -x; docker push $IMAGE; set +x; exit;;

         *) die "Unknown option '$1'";;
    esac
    shift
done


## Main: ----------------------------------------------------------------------

BUILD_0
 
