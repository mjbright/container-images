

DATE_VERSION=$(date +%Y-%b-%d_%02Hh%02Mm%02S)

BASE_IMAGE="mjbright/docker-demo"

let START_S=SECONDS

PROG="--progress plain"
PROG=""

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
        #PICTURE_PATH_BASE="static/img/kubernetes_$PICTURE_COLOUR"
        PICTURE_PATH_BASE="docker_$PICTURE_COLOUR"

        sed \
           -e "s?FROM_IMAGE?$FROM_IMAGE?" \
	   Dockerfile.tmpl > Dockerfile

        sed \
           -e "s/TEMPLATE_LIVENESS/OK/" \
           -e "s?__TEMPLATE_CMD__?$TEMPLATE_CMD?" \
           -e "s?TEMPLATE_REPLACE_LOGO?${PICTURE_PATH_BASE}.txt?" \
           -e "s?TEMPLATE_IMAGE_NAME_VERSION?$IMAGE_NAME_VERSION?" \
           -e "s/TEMPLATE_IMAGE_VERSION/$IMAGE_VERSION/" \
           -e "s/TEMPLATE_LIVENESS/OK/" \
           -e "s/TEMPLATE_READINESS/OK/" \
	   demo-main-go.tmpl > demo-main.go

           #-e "s/__DATE_VERSION__/$DATE_VERSION/" \
           #-e "s/__FROM_IMAGE__/$FROM_IMAGE/" \
           #-e "s/__BUILD_ENV_TARGET__/$BUILD_ENV_TARGET/" \
           #-e "s/__STAGE1_BUILD__/$STAGE1_BUILD/" \
           #-e "s/__EXPOSE_PORT__/$EXPOSE_PORT/" \
           #-e "s/__PICTURE_COLOUR__/$PICTURE_COLOUR/" \
           #-e "s?__PICTURE_PATH_BASE__?$PICTURE_PATH_BASE?" \
           #Dockerfile.tmpl > Dockerfile
           #templates/Dockerfile.tmpl > Dockerfile

	set -x
        docker build -f Dockerfile -t $IMAGE_NAME_VERSION $PROG .
	#exit
	set +x
    done
done

let END_S=SECONDS
let TOOK_S=END_S-START_S

echo "Took $TOOK_S seconds"

