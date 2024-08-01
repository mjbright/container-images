
IMAGE=mjbright/kubectl-proxy:1

docker build . -t $IMAGE --progress=plain
docker image ls   $IMAGE

docker login
docker push $IMAGE

