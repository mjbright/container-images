
# Get the name of one of the Pods:
POD1=$( kubectl get pods -l app=1-no-probes-pod-status --no-headers | awk '{ print $1; exit(0); }' )

echo; echo "See Pod status transitions (in status: section):"
set -x
kubectl get pod $POD1 -o yaml | grep -A40 '^status:' | grep -E 'TransitionTime:|type:'
set +x

echo; echo "See Pod events (from kubectl describe pod):"
set -x
kubectl describe pod $POD1 | grep -A40 '^Events:'
set +x

echo; echo "See Pod events (from kubectl get events):"
set -x
kubectl events --for pod/$POD1
set +x

