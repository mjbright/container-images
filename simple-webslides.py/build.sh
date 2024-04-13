#!/bin/bash

FLASK_IMAGE="mjbright/simple-webslides:flask"

press() {
    echo "$*"
    echo "Press <enter>"
    read DUMMY
    [ "$DUMMY" = "q" ] && exit 0
    [ "$DUMMY" = "Q" ] && exit 0
}

die() {
    echo "$0: die - $*" >&2
    exit 1
}

CONTAINER_IMAGE=mjbright/simple-webslides:bg
BUILD_ARGS="--build-arg CONTAINER_IMAGE=$CONTAINER_IMAGE"
set -x
    docker build -f Dockerfile.htmltext $BUILD_ARGS -t $CONTAINER_IMAGE . || die "Build failed"
set +x

CONTAINER_IMAGE=mjbright/simple-webslides:img
BUILD_ARGS="--build-arg CONTAINER_IMAGE=$CONTAINER_IMAGE"
set -x
    docker build -f Dockerfile.images   $BUILD_ARGS -t $CONTAINER_IMAGE . || die "Build failed"
set +x

echo "$FLASK_IMAGE" > flask.templates/container.image.txt
CONTAINER_IMAGE=$FLASK_IMAGE
BUILD_ARGS="--build-arg CONTAINER_IMAGE=$CONTAINER_IMAGE"
set -x
    docker build -f Dockerfile.flask $BUILD_ARGS -t $CONTAINER_IMAGE . || die "Build failed"
set +x

echo; press "About to push images"

set -x
docker push mjbright/simple-webslides:bg
docker push mjbright/simple-webslides:img
docker push $FLASK_IMAGE
set +x

