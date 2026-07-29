
echo "Error: Need to create Pod with extra ephemeral storage"
echo

cat <<EOF
Events:
  Type     Reason   Age   From     Message
  ----     ------   ----  ----     -------
  Warning  Evicted  11m   kubelet  The node was low on resource: ephemeral-storage. Threshold quantity: 2328468572, available: 1699532Ki. Container kube-tools was using 7101408Ki, request is 0, has larger consumption of ephemeral-storage.
  Normal   Killing  11m   kubelet  spec.containers{kube-tools}: Stopping container kube-tools
EOF

echo
echo "Consider filtering on krew plugin names ?"
exit
kubectl krew install $( kubectl krew search | awk '!/^NAME/ { print $1; }' )

