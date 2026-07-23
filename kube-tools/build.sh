
IMAGE=docker.io/mjbright/kube-tools:1
BUILDER=docker
BUILDER="sudo podman"

die() { echo "$0: die - $*" >&2; exit 1; }

set -x
$BUILDER build . -t $IMAGE --progress=plain || die "Build failed"

$BUILDER image ls   $IMAGE  || die "image ls failed"
$BUILDER login              || die "login failed"
$BUILDER push $IMAGE        || die "push failed"

