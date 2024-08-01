#!/usr/bin/env sh

URL=$1
# e.g URL=/apis/apps/v1/namespaces/default/deployments
OBJECT_TYPE=$( echo $URL | sed -e 's?.*/??' )

/kubectl-proxy.sh &
sleep 2

#LIST=$( wget -qO - 127.0.0.1:8001$URL | jq .items )
LIST=$( wget -qO - 127.0.0.1:8001$URL | jq -r .items[].metadata.name )
[ -z "$LIST" ] && LIST="<none>"

echo "$OBJECT_TYPE: $LIST"

