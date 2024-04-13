#!/usr/bin/env bash

PORT=9000
IMAGE_BASE=docker.io/mjbright/k8s-demo:py
IMAGE=${IMAGE_BASE}0

RUNNER=docker
#RUNNER=podman

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

## Args: ----------------------------------------------------------------------

while [ $# -ne 0 ]; do
    case $1 in
        -rm)
            RUN "$RUNNER rm -f $($RUNNER ps -aq)"
            #RUN "$RUNNER container prune -f"
            exit $?
            ;;
        -[0-9]|[0-9]) IDX=${1#-}; IMAGE=${IMAGE_BASE}${IDX};
            #echo "Set IDX=$IDX; IMAGE=$IMAGE"; exit 0
            ;;
    esac
    shift
done

 
## Main: ----------------------------------------------------------------------

$RUNNER ps | grep :${PORT}- && die "Port ${PORT} is already in use"

RUN $RUNNER run -d -p ${PORT}:8080 $IMAGE

RUN $RUNNER ps

