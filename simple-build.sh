

DATE_VERSION=$(date +%Y-%b-%d_%02Hh%02Mm%02S)

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
        IMAGE_NAME_VERSION="mjbright/k8s-demo:$V"
        [ $FROM_IMAGE = "alpine" ] && IMAGE_NAME_VERSION="mjbright/k8s-demo:alpine$V"
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
        PICTURE_PATH_BASE="static/img/kubernetes_$PICTURE_COLOUR"

        sed \
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
        docker build -f Dockerfile -t $IMAGE_NAME_VERSION .
	set +x
    done
done

let END_S=SECONDS
let TOOK_S=END_S-START_S

echo "Took $TOOK_S seconds"

