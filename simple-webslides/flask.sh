#!/bin/sh

PORT=9000
BIND=0.0.0.0

C_IMAGE=""
BG_COLOR="bg-green"

FLASK=0

HTML_FILES="index.html"

die() {
    echo "$0: die - $*" >&2
    exit 1
}

hostname=$(hostname)
SET_FLASK() {
    sed \
        -e "s/__HOSTNAME__/${hostname}/" \
        -e "s/__BG_COLOR__/${BG_COLOR}/" \
        -e "s/__IMAGE__/${IMAGE}/" \
        -e "s?__C_IMAGE__?${C_IMAGE}?"
    [ $? -ne 0 ] && die "SET_FLASK: Error on sed"
        #-e "s/__C_IMAGE__/${C_IMAGE}/" \
        #| tee flask.templates/${HTML_FILE}
}

while [ ! -z "$1" ]; do
    case $1 in
        --ci)         shift; C_IMAGE="$1";;
        --html-files) shift; HTML_FILES="$1";;

        *:*) BIND_PORT=$1;
            BIND=${BIND_PORT%%:*}
            PORT=${BIND_PORT##*:}
            ;;
        [0-9]*\.[0-9]*) BIND=$1;;
        [0-9]*)         PORT=$1;;
    esac
    shift
done

echo "Creating $HTML_FILES from template(s)"
for HTML_FILE in $HTML_FILES; do
    #cat ${HTML_FILE}.templ| SET_FLASK| grep -v background-image > ${HTML_FILE}
    cat ${HTML_FILE}.templ| SET_FLASK| grep -v background-image > flask.templates/${HTML_FILE}
    #cp -a $HTML_FILE flask.templates/${HTML_FILE}

    #diff ${HTML_FILE}.templ ${HTML_FILE}
    diff ${HTML_FILE}.templ flask.templates/${HTML_FILE}
    ls -al ${HTML_FILE}.templ ${HTML_FILE} flask.templates/${HTML_FILE}
    [ ! -s flask.templates/${HTML_FILE} ] && die "Empty file flask.templates/$HTML_FILE"
done

while true; do
    echo "Starting Flask web server on ${BIND}:${PORT}"

    PYTHON=$(which python3)
    [ -z "$PYTHON" ] && PYTHON=python

    $PYTHON -m py_compile app.py && $PYTHON app.py -p $PORT
    sleep 2;
done

