
kubectl krew install $( kubectl krew search | awk '!/^NAME/ { print $1; }' )

