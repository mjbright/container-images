
#IMAGE=k8spatterns/kubeapi-proxy
#IMAGE=mjbright/kubectl-proxy
#IMAGE=mjbright/kubeapi:py

# kubectl run -it --rm testkube --image $IMAGE -- sh
kubectl create -f wget-ambassador.yaml
