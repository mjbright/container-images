
# Get the name of one of the Pods:
POD1=$( kubectl get pods -l app=1-no-probes-pod-status --no-headers | awk '{ print $1; exit(0); }' )

set -x
kubectl logs $POD1 -c init-1
kubectl logs $POD1 -c init-2
kubectl logs $POD1 -c init-3
kubectl logs $POD1 -c init-4
kubectl logs $POD1 -c k8s-demo
kubectl logs $POD1 -c sleeper
set +x

