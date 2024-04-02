
# e.g. ./run.sh -p 9001 flask
# e.g. ./run.sh -p 9001 bg
# e.g. ./run.sh -p 9001 image

PORT=9000

IMAGE=mjbright/simple-webslides:bg

while [ ! -z "$1" ]; do
    case $1 in
        -p) shift; PORT=$1;;
        html|bg) IMAGE=mjbright/simple-webslides:bg;;
        flask)  IMAGE=mjbright/simple-webslides:flask;;
        img|image) IMAGE=mjbright/simple-webslides:img;;
    esac
    shift
done

set -x
docker run --rm -p $PORT:9000 $IMAGE

