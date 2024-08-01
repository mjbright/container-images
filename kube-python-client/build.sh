
IMAGE=mjbright/kubeapi:py

docker build . -t $IMAGE --progress=plain
docker image ls   $IMAGE

docker login
docker push $IMAGE


