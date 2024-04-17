POD1=$( kubectl get pods -l app=1-no-probes-pod-status --no-headers | awk '{ print $1; exit(0); }' )
kubectl get pod $POD1 -o yaml | grep -A40 '^status:' | grep -E 'TransitionTime:|type:'
