#!/usr/bin/env bash

IMAGE_BASE=mjbright/labs:py
IMAGE=${IMAGE_BASE}

BUILDER=docker
#BUILDER=podman

LOGGEDIN=0
PUSH="registry"

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

LOGIN() {
    [ $LOGGEDIN -ne 0 ] && return

    RUN $BUILDER login
    LOGGEDIN=1
}

BUILD() {
    IMAGE=$1; shift

    [ "$PUSH" = "registry" ] && LOGIN

    if [ "$BUILDER" = "docker" ]; then
        RUN docker build -t $IMAGE . --progress plain
        RUN PUSH $IMAGE
    else
        RUN podman build -t $IMAGE .
        RUN podman login
        RUN PUSH $IMAGE
    fi
}

CREATE_TMP_HTTPD_PY() {
    # set -x
    # httpd.py is the template for generating tmp/httpd.py which is builtin into the image
    sed httpd.py \
            -e "s?^ASCIITEXT=.*?ASCIITEXT=\"$ASCIITEXT\"?" \
            -e "s?^PNG=.*?PNG=\"$PNG\"?"                   \
            -e "s?^IMAGE=.*?IMAGE=\"$IMAGE\"?"             \
            > tmp/httpd.py
    # set +x

    chmod +x tmp/httpd.py
    ls   -al tmp/httpd.py
    [ ! -s tmp/httpd.py ] && die "sed failed when creating tmp/httpd.py"
    #exit

    CMD="diff httpd.py tmp/httpd.py"
    echo; echo "-- $CMD"; $CMD
    #read
}

BUILD_BASE() {
    C="blue"; ASCIITEXT="static/img/kubernetes_${C}.txt"; PNG="static/img/kubernetes_${C}.png"
    CREATE_TMP_HTTPD_PY
    BUILD $IMAGE

    # RUN $BUILDER image tag $IMAGE ${IMAGE%0}
    # RUN PUSH ${IMAGE%0}
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

    BUILD_BASE
}

DELETE_ALL_IMAGES() {
    for IDX in {1..6}; do
        IMAGE=${IMAGE_BASE}${IDX}
        RUN $BUILDER image remove $IMAGE
    done

    #IMAGE=${IMAGE_BASE};   RUN $BUILDER image remove $IMAGE
    IMAGE=${IMAGE_BASE};    RUN $BUILDER image remove $IMAGE

    #[ "$BUILDER" = "docker" ] && $BUILDER image prune
    RUN $BUILDER image prune -f
    RUN $BUILDER image ls
}

PUSH() {
    IMAGE=$1

    case $PUSH in
         registry)    $BUILDER push $IMAGE;;

         nerdctl)     echo "Images are large[1 GBy], save/load will take time ..."; set -x; $BUILDER image save $IMAGE | sudo nerdctl -n k8s.io image load; set +x;;

         *) die "Unknown 'image push' option '$PUSH'";;
    esac
}

## Args: ----------------------------------------------------------------------

which docker && BUILDER=docker ||
    which podman && BUILDER=podman

while [ $# -ne 0 ]; do
    case $1 in
        # Push images to containerd/k8s.io namespace on local node:
        -lp|--local-push) PUSH="nerdctl";;

        -np|--no-prompts) PROMPTS=0;;

        -d|--docker) BUILDER=docker;;
        -P|--podman) BUILDER=podman;;

        -rmi) PROMPTS=0; DELETE_ALL_IMAGES; exit $?;;
        -a)   PROMPTS=0; BUILD_ALL; exit $?;;

        -p)   set -x; PUSH $IMAGE; set +x; exit;;

         *) die "Unknown option '$1'";;
    esac
    shift
done


## Main: ----------------------------------------------------------------------

cd $( dirname $0 )
mkdir -p tmp

echo "Using $BUILDER:"

BUILD_BASE
 
