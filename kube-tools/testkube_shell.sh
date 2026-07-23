
IMAGE=k8spatterns/kubeapi-proxy
#IMAGE=mjbright/kubeapi:py

kubectl run -it --rm testkube --image $IMAGE -- sh
