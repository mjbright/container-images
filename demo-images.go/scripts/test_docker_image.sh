#!/usr/bin/env bash
# The historical filename is retained, but this smoke test uses Finch.
set -euo pipefail
image="${1:?Usage: scripts/test_docker_image.sh IMAGE [amd64,arm64] [PORT]}"
platform_csv="${2:-linux/amd64,linux/arm64}"
port="${3:-18080}"
pull="${PULL_POLICY:-never}"
case "$pull" in always|missing|never) ;; *) printf 'Invalid PULL_POLICY\n' >&2; exit 1 ;; esac
if ! [[ "$port" =~ ^[0-9]{1,5}$ ]] || ! ((10#$port >= 1024 && 10#$port <= 65535)); then
    printf 'Port must be between 1024 and 65535\n' >&2
    exit 1
fi
[[ -n "$platform_csv" && "$platform_csv" != ,* && "$platform_csv" != *, && "$platform_csv" != *,,* ]] ||
    { printf 'Invalid platform list\n' >&2; exit 1; }
IFS=, read -r -a items <<< "$platform_csv"
platforms=()
for platform in "${items[@]}"; do
    case "$platform" in
        amd64|x86_64|linux/amd64) platforms+=(linux/amd64) ;;
        arm64|aarch64|linux/arm64|linux/aarch64) platforms+=(linux/arm64) ;;
        *) printf 'Unsupported platform: %s\n' "$platform" >&2; exit 1 ;;
    esac
done
command -v finch >/dev/null 2>&1
command -v curl >/dev/null 2>&1
container_id=""
cleanup() {
    if [[ -n "$container_id" ]]; then
        finch rm --force "$container_id" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
for platform in "${platforms[@]}"; do
    printf 'Smoke test %s on %s (pull=%s)\n' "$image" "$platform" "$pull"
    # Capture the exact ID; cleanup never selects other users' containers.
    container_id="$(finch run --detach --pull "$pull" --platform "$platform" \
        --publish "127.0.0.1:$port:80" "$image")"
    [[ -n "$container_id" ]] || { printf 'No container ID returned\n' >&2; exit 1; }
    response=""
    ready=false
    for ((attempt=0; attempt<30; attempt++)); do
        if response="$(curl -fsS --max-time 2 "http://127.0.0.1:$port/version" 2>/dev/null)"; then
            ready=true
            break
        fi
        sleep 1
    done
    if ! "$ready"; then
        finch logs "$container_id" >&2 || true
        printf 'Container did not become ready\n' >&2
        exit 1
    fi
    [[ "$response" == *"platform: $platform"* ]] ||
        { printf 'Wrong architecture: %s\n' "$response" >&2; exit 1; }
    curl -fsS --max-time 5 "http://127.0.0.1:$port/ping" >/dev/null
    curl -fsS --max-time 5 "http://127.0.0.1:$port/" >/dev/null
    html="$(curl -fsS --max-time 5 -A 'Mozilla/5.0' "http://127.0.0.1:$port/")"
    [[ "$html" == *'Served from'* ]] || { printf 'HTML rendering failed\n' >&2; exit 1; }
    # Fetch the logo named by the built-in HTML template.
    logo="$(printf '%s\n' "$html" | sed -n 's/.*<img src="\([^"]*\)".*/\1/p')"
    [[ "$logo" == static/img.*/*.png ]] || { printf 'Missing logo path\n' >&2; exit 1; }
    curl -fsS --max-time 5 "http://127.0.0.1:$port/$logo" >/dev/null
    cleanup
    container_id=""
    printf 'PASS %s\n' "$platform"
done
