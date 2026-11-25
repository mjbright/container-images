
BUILDER=docker
ACCOUNT=mjbright
ARCH="linux/amd64,linux/arm64"
BASE_IMAGE=unset
TAGS=""
#TAGS="v1 v2"

# finch rm -f $( finch ps -aq )
# finch image rm -f mjbright/backend:v1
# finch image rm -f mjbright/backend:v2

# cd $( dirname $0 )

# -- Func: --------------------------------------------------------------------------------

die() { echo "$0: $*" >&2; exit 1; }

DOCKER_LOGIN() {
    read -s -p "Enter 'docker login' password for user '$ACCOUNT': " MDP
    echo $MDP | { set -x; $BUILDER login --username $ACCOUNT --password-stdin; set +x; }
}

DOCKER_REMOVE() {
    local BASE_IMAGE=$1; shift
    local TAG=$1; shift
    local IMAGE=${BASE_IMAGE}:${TAG}
    [ -z "$TAG" ] && IMAGE=${BASE_IMAGE}

    set -x; $BUILDER image rm -f $ACCOUNT/$IMAGE; set +x
}

DOCKER_BUILD() {
    local BASE_IMAGE=$1; shift
    local TAG=$1; shift
    local IMAGE=${BASE_IMAGE}:${TAG}
    [ -z "$TAG" ] && IMAGE=${BASE_IMAGE}

    set -x
    $BUILDER build --platform $ARCH -t $ACCOUNT/$IMAGE . || die "[$PWD] Build of $ACCOUNT/$IMAGE failed"
    $BUILDER image ls | grep $ACCOUNT/$BASE_IMAGE || die "Image not found matching '$ACCOUNT/$BASE_IMAGE'"
    set +x
}

DOCKER_PUSH() {
    local BASE_IMAGE=$1; shift
    local TAG=$1; shift
    local IMAGE=${BASE_IMAGE}:${TAG}
    [ -z "$TAG" ] && IMAGE=${BASE_IMAGE}

    set -x; $BUILDER push --platform $ARCH $ACCOUNT/$IMAGE; set +x
}

# -- Args: --------------------------------------------------------------------------------

pwd
ls -al .cbuild
[ -f ~/.cbuild ] && { echo "source ~/.cbuild"; source ~/.cbuild; }
[ -f   .cbuild ] && { echo "source   .cbuild"; source   .cbuild; }

if [ "$1" = "-l" ]; then
    DOCKER_LOGIN
    exit $?
fi

REMOVE=0
[ "$1" = "-rm" ] && { REMOVE=1; shift; }
LIST=0
[ "$1" = "-ls" ] && { LIST=1; shift; }

[ ! -z "$1" ] && { BASE_IMAGE=$1; shift; }
[ ! -z "$1" ] && { TAGS=$1; shift; }
[ -z "$BASE_IMAGE" ] && die "Usage: $0 <BASE_IMAGE> [<TAGS>]"

# -- Main: --------------------------------------------------------------------------------

if [ $LIST -ne 0 ]; then
    $BUILDER image ls | grep $BASE_IMAGE
    exit $?
fi

if [ -z "$TAGS" ]; then
    if [ $REMOVE -ne 0 ]; then
        DOCKER_REMOVE $BASE_IMAGE ""
    else
        DOCKER_BUILD $BASE_IMAGE ""
        DOCKER_PUSH  $BASE_IMAGE ""
    fi
else
    for TAG in $TAGS; do
        echo "TAG=$TAG"
        case $TAG in
	    "") ;;
            v1) cp -a Dockerfile.v1 Dockerfile;;
            v2) cp -a Dockerfile.v2 Dockerfile;;
        esac
        if [ $REMOVE -ne 0 ]; then
            DOCKER_REMOVE $BASE_IMAGE $TAG
	else
            DOCKER_BUILD $BASE_IMAGE $TAG
            DOCKER_PUSH  $BASE_IMAGE $TAG
	fi
    done
fi

