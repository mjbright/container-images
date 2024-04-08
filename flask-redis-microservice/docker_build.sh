#!/usr/bin/env bash

cd $( dirname $0 )

QUICK_BUILD=0
PROMPTS=0
D_USER=mjbright
##D_IMAGE=${D_USER}/dronestore:0.1

HUB_PUSH=0

APP="flask-web"
VERSIONS="0 1 2 3"

# Build all three versions of our application:

## -- Func: ---------------------------------------------------------------

die() { echo "$0: die - $*" >&2; exit 1; }

PRESS() {
    echo
    echo $*
    [ $PROMPTS -eq 0 ] && return

    echo "Press <enter> to continue"
    read DUMMY
    [ "$DUMMY" = "q" ] && exit 0
    [ "$DUMMY" = "Q" ] && exit 0
}

## -- Args: ---------------------------------------------------------------

while [ $# -gt 0 ]; do
    case $1 in
        -np)       PROMPTS=0;;
        -p)        PROMPTS=1;;
        -nc)       BUILD_ARGS+=" --no-cache";;
        --nocache) BUILD_ARGS+=" --no-cache";;
        -push)     HUB_PUSH=1;;

        -q)        QUICK_BUILD=1;;

        *) die "Unknown option <$1>";;
    esac
    shift
done

## -- Main: ---------------------------------------------------------------

which docker 2>/dev/null && {
    BUILD_ARGS="--progress plain"
    BUILDER=$(which docker 2>/dev/null)
}

[ -z "$BUILDER" ] && {
     BUILDER=$(which podman 2>/dev/null)
     BUILD_ARGS=""
}
[ -z "$BUILDER" ] && die "Failed to find either docker or podman in PATH"

echo "Using $BUILDER to build images"

[ $HUB_PUSH -ne 0 ] && {
    CMD="$BUILDER login -u ${D_USER}"
    echo "-- $CMD"
    $CMD || die "Failed to login"
}

ARCH=$( uname -m )

case $ARCH in
     x86_64) export TARGETARCH=amd64;;
      amd64) export TARGETARCH=amd64;;
      arm64) export TARGETARCH=arm64;;
    aarch64) export TARGETARCH=arm64;;
          *) die "Unknown architecture $ARCH"
esac

START0=$SECONDS
for version in $VERSIONS; do
    D_IMAGE="$D_USER/$APP:v$version"
    START=$SECONDS

    cp -a versions/app.py.v$version app.py

    CMD="$BUILDER build . $BUILD_ARGS -t ${D_IMAGE}"
    echo; echo "-- $CMD"
    $CMD

    [ $HUB_PUSH -ne 0 ] && {
        CMD="$BUILDER push $D_IMAGE"
        echo "-- $CMD"
        $CMD
    }

    ## -- Arch: ---------------------------------------------------------------
    if [ $QUICK_BUILD -eq 0 ]; then
        echo
        PRESS "Building $D_IMAGE for multiple architectures"
        # See:
        # - https://www.docker.com/blog/how-to-rapidly-build-multi-architecture-images-with-buildx/
        docker buildx ls
        docker buildx create --name multi-builder --use --bootstrap
        docker buildx ls

        # Now, you’ll jumpstart your multi-architecture build with the single docker buildx command shown below:

        docker buildx build --push --progress plain --platform linux/amd64,linux/arm64 -t ${D_IMAGE} .
     fi
     END=$SECONDS

     let TOOK=END-START
     echo "[TOOK $TOOK secs] Build of $D_IMAGE"
done

let TOOK=END-START0
echo "[TOOK $TOOK secs] Build of all versions[$VERSIONS]"

#docker search $D_USER/$APP


