

#DATE_VERSION=$(date +%Y-%b-%d_%02Hh%02Mm%02S)
DATE_VERSION=$(date +%Y-%b-%d_%02Hh%02Mm)
PROG="--progress plain"
PROG=""

IP=$( curl -s --connect-timeout 2 ifconfig.io )
H=$( hostname )
case $IP in
    178.63.102.36) H="hetzner1";;
esac

BUILD_REPO=$( git remote -v | sed -e 's/.*github/github/' -e 's/ .*//' | head -1 )
BUILD_DIR=$( basename $PWD )
BUILD_INFO="[$USER@$H - $DATE_VERSION - $BUILD_REPO - $BUILD_DIR ]"
#echo "BUILD_INFO='$BUILD_INFO'"
#exit

TODO="
30      40      Black
31      41      Red
32      42      Green
33      43      Yellow
34      44      Blue
35      45      Magenta
36      46      Cyan
37      47      White
90      100     Bright Black (Gray)
91      101     Bright Red
92      102     Bright Green
93      103     Bright Yellow
94      104     Bright Blue
95      105     Bright Magenta
96      106     Bright Cyan
97      107     Bright White
"

## -- Func: --------------------------------------------------------------------------------
die() { echo "$0: die - $*">&2; exit 1; }

BUILD_IMAGES() {
    BASE_IMAGE=$1; shift

    let START_S=SECONDS

    for FROM_IMAGE in scratch alpine; do
        BUILD_ENV_TARGET="build-env-static"
        STAGE1_BUILD="CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-w' -o demo-binary main.build.go"
        [ $FROM_IMAGE = "alpine" ] && {
            BUILD_ENV_TARGET="build-env-dynamic"
            STAGE1_BUILD="CGO_ENABLED=0 go build -a -o demo-binary main.build.go"
        }

        PORT=80
        EXPOSE_PORT=$PORT
        TEMPLATE_CMD="[\"/app/demo-binary\",\"-l\",\"$PORT\",\"-L\",\"0\",\"-R\",\"0\"]"

        for V in {1..6}; do
            PICTURE_COLOUR="blue"
            IMAGE_NAME_VERSION="$BASE_IMAGE:$V"
            [ $FROM_IMAGE = "alpine" ] && IMAGE_NAME_VERSION="$BASE_IMAGE:alpine$V"
            IMAGE_VERSION=$V

            case $V in
		1) PICTURE_COLOUR="blue" ;;
		2) PICTURE_COLOUR="green" ;;
		3) PICTURE_COLOUR="red" ;;
		4) PICTURE_COLOUR="cyan" ;;
		5) PICTURE_COLOUR="yellow" ;;
		6) PICTURE_COLOUR="white" ;;
		#*) ;;
	    esac

            IMAGE_GROUP="kubernetes"
	    case $BASE_IMAGE in
                *k8s*)    IMAGE_GROUP=kubernetes;;
                *docker*) IMAGE_GROUP=docker;;
                *tf*)     IMAGE_GROUP=terraform;;
	    esac
            PICTURE_PATH_BASE="static/img.${IMAGE_GROUP}/${IMAGE_GROUP}_$PICTURE_COLOUR"

            sed \
               -e "s?__BUILD_INFO__?$BUILD_INFO?" \
               -e "s/__IMAGE_GROUP__/$IMAGE_GROUP/g" \
               -e "s/__DATE_VERSION__/$DATE_VERSION/" \
               -e "s/__FROM_IMAGE__/$FROM_IMAGE/" \
               -e "s/__BUILD_ENV_TARGET__/$BUILD_ENV_TARGET/" \
               -e "s/__STAGE1_BUILD__/$STAGE1_BUILD/" \
               -e "s?__TEMPLATE_CMD__?$TEMPLATE_CMD?" \
               -e "s/__EXPOSE_PORT__/$EXPOSE_PORT/" \
               -e "s/__PICTURE_COLOUR__/$PICTURE_COLOUR/" \
               -e "s?__PICTURE_PATH_BASE__?$PICTURE_PATH_BASE?" \
               -e "s?__IMAGE_NAME_VERSION__?$IMAGE_NAME_VERSION?" \
               -e "s/__IMAGE_VERSION__/$IMAGE_VERSION/" \
               templates/Dockerfile.tmpl > Dockerfile

	    set -x
            docker build -f Dockerfile -t $IMAGE_NAME_VERSION $PROG . ||
		    die "Build failed"
	    set +x
	    #read -p "Press <enter>"
        done
    done

    let END_S=SECONDS
    let TOOK_S=END_S-START_S
    
    echo "[$BASE_IMAGE:*] Took $TOOK_S seconds"
}

RUN_IMAGES() {
    docker run --name k-1       -d -p 7001:80 mjbright/k8s-demo:1
    docker run --name k-alpine1 -d -p 7011:80 mjbright/k8s-demo:alpine1
    docker run --name k-2       -d -p 7002:80 mjbright/k8s-demo:2
    docker run --name k-alpine2 -d -p 7012:80 mjbright/k8s-demo:alpine2

    docker run --name d-1       -d -p 8001:80 mjbright/docker-demo:1
    docker run --name d-alpine1 -d -p 8011:80 mjbright/docker-demo:alpine1
    docker run --name d-2       -d -p 8002:80 mjbright/docker-demo:2
    docker run --name d-alpine2 -d -p 8012:80 mjbright/docker-demo:alpine2
}

STOP_IMAGES() {
    #docker rm -f c-1 c-alpine1
    TOSTOP=$(  docker ps | awk '/\/app\/demo-binary/ { print $1; }' )
    [ ! -z "$TOSTOP" ] && docker rm -f $TOSTOP
    docker ps -a
}

TEST_IMAGES() {
    docker ps
    sleep 2
        { set -x; curl -s 127.0.0.1:7001 | tail -6; curl -s 127.0.0.1:7001/1; docker exec -it k-1 hostname; } | sed 's/^/    /'
	read -p "Press <enter>"

        { set -x; curl -s 127.0.0.1:7011 | tail -6; curl -s 127.0.0.1:7011/1; docker exec -it k-alpine1 hostname; } | sed 's/^/    /'
	read -p "Press <enter>"

        { set -x; curl -s 127.0.0.1:8001 | tail -6; curl -s 127.0.0.1:8001/1; docker exec -it d-1 hostname; } | sed 's/^/    /'
	read -p "Press <enter>"

        { set -x; curl -s 127.0.0.1:8011 | tail -6; curl -s 127.0.0.1:8011/1; docker exec -it d-alpine1 hostname; } | sed 's/^/    /'
	read -p "Press <enter>"

    set +x
}

REMOVE_IMAGES() {
    for V in {1..6}; do
	 #   set -x
        docker image rm mjbright/docker-demo:$V
        docker image rm mjbright/docker-demo:alpine$V
        docker image rm mjbright/k8s-demo:$V
        docker image rm mjbright/k8s-demo:alpine$V
        docker image rm mjbright/tf-demo:$V
        docker image rm mjbright/tf-demo:alpine$V
	 #   set +x
    done 2>/dev/null
    docker image prune -f
    docker image ls
}

## -- Args: --------------------------------------------------------------------------------
#
case "$1" in
       -run) RUN_IMAGES; exit;;
  -stop|-rm) STOP_IMAGES; exit;;
      -test) RUN_IMAGES; TEST_IMAGES; exit;;
       -rmi) REMOVE_IMAGES; exit;;
esac

## -- Main: --------------------------------------------------------------------------------

BUILD_IMAGES "mjbright/k8s-demo"
BUILD_IMAGES "mjbright/docker-demo"
#BUILD_IMAGES "mjbright/tf-demo"


