
IMAGE=mjbright/ubuntu:24.04

docker build . -t $IMAGE --progress=plain
docker image ls   $IMAGE

docker login
docker push $IMAGE
