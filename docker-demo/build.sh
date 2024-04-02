#!/bin/bash

VERSIONS=6

CACHE="--no-cache"

################################################################################
# Functions:

die() {
    echo "$0: die - $*" >&2
    exit 1
}

push_images() {
    for image in $*; do
        echo; echo "push $image"
        docker push $image
    done
}

build_image() {
    TXT_IMAGE=$1; shift
    PNG_IMAGE=$1; shift
    IMAGE_NAME_VERSION=$1; shift
    LIVENESS=$1; shift
    READINESS=$1; shift
    # e.g. build_image "docker_blue.txt"   "docker_blue.png"   mjbright/docker-demo:1 "OK" "OK"

    IMAGE_VERSION=${IMAGE_NAME_VERSION#*:}

    echo; echo "---- Building image $IMAGE_NAME_VERSION [VERSION:$IMAGE_VERSION]"

    sed -e "s/TEMPLATE_REPLACE_LOGO/$TXT_IMAGE/" \
        -e "s?TEMPLATE_IMAGE_NAME_VERSION?$IMAGE_NAME_VERSION?" \
        -e "s/TEMPLATE_IMAGE_VERSION/$IMAGE_VERSION/" \
        -e "s/TEMPLATE_LIVENESS/$LIVENESS/" \
        -e "s/TEMPLATE_READINESS/$READINESS/" \
        demo-main-go.tmpl > main.go

    IMAGE_NAME=${IMAGE_NAME_VERSION%:*}
    USE_IMAGE_NAME=$(echo $IMAGE_NAME | sed -e 's?/?_?g')
    #echo "IMAGE_NAME_VERSION=${IMAGE_NAME_VERSION}"
    #echo "IMAGE_NAME=${IMAGE_NAME}"
    #echo "USE_IMAGE_NAME=${USE_IMAGE_NAME}"
    mkdir -p tmp
    DEST=tmp/main_${USE_IMAGE_NAME}_${IMAGE_VERSION}.go
    echo cp -a main.go $DEST
    cp -a main.go $DEST
    #exit 0

    sed "s/REPLACE_LOGO/$PNG_IMAGE/" templates/index.html.tmpl.tmpl > templates/index.html.tmpl

    set -x
    docker build $CACHE -t $IMAGE_NAME_VERSION .
    set +x
}

################################################################################
# Main:

PUSH=0

BUILD_DD=1
BUILD_K8=0
BUILD_CK=0
BUILD_BAD=0

die "DEPRECATED ... use mjbright/ckad-demo"

while [ ! -z "$1" ]; do
    case $1 in
        -x) set -x;;
           -a) BUILD_DD=1; BUILD_K8=1; BUILD_CK=1;;
        -push) PUSH=1;;
            *) die "Unknown option <$1>";;
    esac
    shift
done

#if [ $PUSH -ne 0 ]; then
    echo; echo "Docker login:"
    if [ ! -z "$DHUB_PWD" ];then
        [ -z "$DHUB_USER" ] && die "Must set DHUB_USER if DHUB_PWD is used"

        echo "$DHUB_PWD" | docker login --username $DHUB_USER --password-stdin
    else
        docker login
    fi
#fi

if [ $BUILD_DD -ne 0 ]; then
    build_image "docker_blue.txt"   "docker_blue.png"   mjbright/docker-demo:1 "OK" "OK"
    build_image "docker_green.txt"  "docker_green.png"  mjbright/docker-demo:2 "OK" "OK"
    build_image "docker_red.txt"    "docker_red.png"    mjbright/docker-demo:3 "OK" "OK"
    build_image "docker_yellow.txt" "docker_yellow.png" mjbright/docker-demo:4 "OK" "OK"
    build_image "docker_cyan.txt"   "docker_cyan.png"   mjbright/docker-demo:5 "OK" "OK"
    build_image "docker_white.txt"  "docker_white.png"  mjbright/docker-demo:6 "OK" "OK"

    if [ $BUILD_BAD -ne 0 ]; then
        build_image "docker_blue.txt"   "docker_blue.png"   mjbright/docker-demo:bad1 "50s" "20s"
        build_image "docker_green.txt"  "docker_green.png"  mjbright/docker-demo:bad2 "50s" "20s"
        build_image "docker_red.txt"    "docker_red.png"    mjbright/docker-demo:bad3 "50s" "20s"
        build_image "docker_yellow.txt" "docker_yellow.png" mjbright/docker-demo:bad4 "50s" "20s"
        build_image "docker_cyan.txt"   "docker_cyan.png"   mjbright/docker-demo:bad5 "50s" "20s"
        build_image "docker_white.txt"  "docker_white.png"  mjbright/docker-demo:bad6 "50s" "20s"
    fi
fi

if [ $BUILD_K8 -ne 0 ]; then
    build_image "kubernetes_blue.txt"   "kubernetes_blue.png"   mjbright/k8s-demo:1 "OK" "OK"
    build_image "kubernetes_green.txt"  "kubernetes_green.png"  mjbright/k8s-demo:2 "OK" "OK"
    build_image "kubernetes_red.txt"    "kubernetes_red.png"    mjbright/k8s-demo:3 "OK" "OK"
    build_image "kubernetes_yellow.txt" "kubernetes_yellow.png" mjbright/k8s-demo:4 "OK" "OK"
    build_image "kubernetes_cyan.txt"   "kubernetes_cyan.png"   mjbright/k8s-demo:5 "OK" "OK"
    build_image "kubernetes_white.txt"  "kubernetes_white.png"  mjbright/k8s-demo:6 "OK" "OK"

    if [ $BUILD_BAD -ne 0 ]; then
        build_image "kubernetes_blue.txt"   "kubernetes_blue.png"   mjbright/k8s-demo:bad1 "50s" "20s"
        build_image "kubernetes_green.txt"  "kubernetes_green.png"  mjbright/k8s-demo:bad2 "50s" "20s"
        build_image "kubernetes_red.txt"    "kubernetes_red.png"    mjbright/k8s-demo:bad3 "50s" "20s"
        build_image "kubernetes_yellow.txt" "kubernetes_yellow.png" mjbright/k8s-demo:bad4 "50s" "20s"
        build_image "kubernetes_cyan.txt"   "kubernetes_cyan.png"   mjbright/k8s-demo:bad5 "50s" "20s"
        build_image "kubernetes_white.txt"  "kubernetes_white.png"  mjbright/k8s-demo:bad6 "50s" "20s"
    fi
fi

if [ $BUILD_CK -ne 0 ]; then
    build_image "kubernetes_blue.txt"   "kubernetes_blue.png"   mjbright/ckad-demo:1 "OK" "OK"
    build_image "kubernetes_green.txt"  "kubernetes_green.png"  mjbright/ckad-demo:2 "OK" "OK"
    build_image "kubernetes_red.txt"    "kubernetes_red.png"    mjbright/ckad-demo:3 "OK" "OK"
    build_image "kubernetes_yellow.txt" "kubernetes_yellow.png" mjbright/ckad-demo:4 "OK" "OK"
    build_image "kubernetes_cyan.txt"   "kubernetes_cyan.png"   mjbright/ckad-demo:5 "OK" "OK"
    build_image "kubernetes_white.txt"  "kubernetes_white.png"  mjbright/ckad-demo:6 "OK" "OK"

    if [ $BUILD_BAD -ne 0 ]; then
        build_image "kubernetes_blue.txt"   "kubernetes_blue.png"   mjbright/ckad-demo:bad1 "50s" "20s"
        build_image "kubernetes_green.txt"  "kubernetes_green.png"  mjbright/ckad-demo:bad2 "50s" "20s"
        build_image "kubernetes_red.txt"    "kubernetes_red.png"    mjbright/ckad-demo:bad3 "50s" "20s"
        build_image "kubernetes_yellow.txt" "kubernetes_yellow.png" mjbright/ckad-demo:bad4 "50s" "20s"
        build_image "kubernetes_cyan.txt"   "kubernetes_cyan.png"   mjbright/ckad-demo:bad5 "50s" "20s"
        build_image "kubernetes_white.txt"  "kubernetes_white.png"  mjbright/ckad-demo:bad6 "50s" "20s"
    fi
fi


#for version in $(seq $VERSIONS); do
#    docker tag mjbright/k8s-demo:$version  mjbright/ckad-demo:$version
#    docker tag mjbright/k8s-demo:bad$version  mjbright/ckad-demo:bad$version
#done

if [ $PUSH -ne 0 ]; then
    IMAGES=""
    for image in mjbright/docker-demo mjbright/k8s-demo mjbright/ckad-demo; do
       for version in $(seq $VERSIONS); do
           IMAGES+="${image}:${version} "
           IMAGES+="${image}:bad${version} "
       done
    done
    
    push_images $IMAGES
fi

exit 0


