#!/usr/bin/env bash
set -euo pipefail
image="${1:?Usage: scripts/kubetest_docker_image.sh IMAGE [PORT] [NAMESPACE]}"
port="${2:-18080}"
namespace="${3:-default}"
if ! [[ "$port" =~ ^[0-9]{1,5}$ ]] || ! ((10#$port >= 1024 && 10#$port <= 65535)); then
    printf 'Port must be between 1024 and 65535\n' >&2
    exit 1
fi
command -v kubectl >/dev/null 2>&1
pod_name="demo-images-test-$(date +%s)-$$"
created=false
cleanup() {
    if "$created"; then
        kubectl --namespace "$namespace" delete pod "$pod_name" --ignore-not-found --wait=false
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
# Avoid the removed --generator option. The node selects its architecture from the OCI index.
kubectl --namespace "$namespace" run "$pod_name" --image="$image" \
    --restart=Never --image-pull-policy=Always --port=80
created=true
kubectl --namespace "$namespace" wait --for=condition=Ready "pod/$pod_name" --timeout=120s
printf 'Use http://127.0.0.1:%s/ ; Ctrl-C cleans up only %s\n' "$port" "$pod_name"
kubectl --namespace "$namespace" port-forward --address 127.0.0.1 "pod/$pod_name" "$port:80"
