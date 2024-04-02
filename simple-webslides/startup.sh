#!/bin/sh

PORT=9000
BIND=0.0.0.0

BG_COLOR="bg-green"
#FLASK=0

SET_HOSTNAME=1
SET_IMAGE=0

HTML_FILES="index.html"

SET_HOSTNAME() {
    [ $SET_HOSTNAME -eq 0 ] && return

    hostname=$(hostname)
    sed -e 's?<div id="hostname">.*</div>?<div id="hostname">[ served from host "'$hostname'"]</div>?'
}

SET_C_IMAGE() {
    sed -e "s?__C_IMAGE__?${C_IMAGE}?"
}

SET_IMAGE() {
    [ $SET_IMAGE -eq 0 ] && { grep -v __IMAGE__;  return; }

    NUM_IMAGES=$(ls -1 static/images/*.jpg | wc -l)
    if [ ! -z "$RANDOM" ]; then
        RND=$(echo ${RANDOM#[0-9]})
    else
        RND=$(date +%S)
        RND=$(echo ${RND#[0-9]})
    fi
    IMAGE=$(ls -1 static/images/*.jpg | head -$RND | tail -1)
    IMAGE=${IMAGE##*/}

    #[ $FLASK -eq 1 ] && { sed "s/__IMAGE__/${IMAGE}/" | tee templates/${HTML_FILE};return; }

    sed -e "s?__IMAGE__?$IMAGE?"
}

SET_BG_COLOR() {
    sed -e "s/__BG_COLOR__/${BG_COLOR}/"
}

while [ ! -z "$1" ]; do
    case $1 in
        #--flask)      FLASK=1;;
        --rnd-image)  SET_IMAGE=1;;
        --html-files) HTML_FILES="$1";;
        --ci)         shift; C_IMAGE="$1";;

        *:*) BIND_PORT=$1;
            BIND=${BIND_PORT%%:*}
            PORT=${BIND_PORT##*:}
            ;;
        [0-9]*\.[0-9]*) BIND=$1;;
        [0-9]*)        PORT=$1;;
    esac
    shift
done

echo "Creating $HTML_FILES from template(s)"
for HTML_FILE in $HTML_FILES; do
    cat ${HTML_FILE}.templ | SET_HOSTNAME | SET_IMAGE | SET_BG_COLOR | SET_C_IMAGE \
	    > ${HTML_FILE}
    diff ${HTML_FILE}.templ ${HTML_FILE}
done

while true; do
    echo "Starting web server on ${BIND}:${PORT}"

    PYTHON=$(which python3)
    [ -z "$PYTHON" ] && PYTHON=python

    #if [ $FLASK -eq 0 ]; then
        $PYTHON -m py_compile app.py && $PYTHON -m http.server --bind $BIND $PORT
    #else
        #$PYTHON -m py_compile app.py && $PYTHON app.py -p $PORT
    #fi
    sleep 2;
done

