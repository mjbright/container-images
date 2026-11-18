#!/usr/bin/env bash
# Bash 3.2 compatible: works with the Bash shipped by macOS.
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
action=build
namespace="${DOCKERHUB_NAMESPACE:-}"
platform_csv="${PLATFORMS:-linux/amd64,linux/arm64}"
group_csv="${GROUPS_TO_BUILD:-k8s,docker}"
variant_csv="${VARIANTS:-scratch,alpine}"
version_csv="${VERSIONS:-1,2,3,4,5,6}"
progress="${PROGRESS:-plain}"
dry_run=false
go_image="${GO_IMAGE:-golang:1.27.4-alpine3.24}"
alpine_image="${ALPINE_IMAGE:-alpine:3.24.4}"
build_date="${DATE_VERSION:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
build_info="${BUILD_INFO:-demo-images Finch build}"
source_revision="${SOURCE_REVISION:-unknown}"
source_url="${SOURCE_URL:-}"
regctl_bin="${REGCTL_BIN:-regctl}"
verify_remote="${VERIFY_REMOTE:-true}"

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
    printf '%s\n' \
        'Usage: ./simple-build.sh [build|push|build-push|login] [options]' \
        '' \
        '  --namespace NAME    Docker Hub user/organization (required, or DOCKERHUB_NAMESPACE)' \
        '  --platforms LIST    Default: linux/amd64,linux/arm64; aarch64 maps to arm64' \
        '  --groups LIST       k8s,docker (default: both)' \
        '  --variants LIST     scratch,alpine (default: both)' \
        '  --versions LIST     1,2,3,4,5,6 (default: all six colours)' \
        '  --progress MODE     auto,plain,tty (default: plain)' \
        '  --dry-run           Print commands without invoking Finch or logging in' \
        '  VERIFY_REMOTE=false  Skip registry manifest verification (not recommended)' \
        '  -h, --help          Show this help' \
        '' \
        'build: build per-platform images locally. push: publish them and assemble the OCI index.' \
        'build-push: finish ALL builds before starting any push.' \
        'login: use Docker Hub credentials; DOCKERHUB_TOKEN is read via stdin if set.' \
        'For an organization, set DOCKERHUB_USERNAME to your login user.' \
        'A multi-platform push uses regctl to assemble the final Docker Hub index.' \
        'Legacy -push is supported. Run tests via scripts/test_docker_image.sh.' \
        'No container deletion, image pruning, or implicit login is performed.'
}

if (($#)); then
    case "$1" in
        build|push|build-push|login) action="$1"; shift ;;
        -push) action=push; shift ;;
        -run|-test|-stop|-rm|-rmi)
            die "Legacy $1 retired for safety; see README.md and scripts/test_docker_image.sh" ;;
    esac
fi

while (($#)); do
    case "$1" in
        --namespace|--platforms|--groups|--variants|--versions|--progress)
            (($# >= 2)) || die "Missing value for $1"
            [[ -n "$2" && "$2" != --* ]] || die "Missing value for $1"
            case "$1" in
                --namespace) namespace="$2" ;;
                --platforms) platform_csv="$2" ;;
                --groups) group_csv="$2" ;;
                --variants) variant_csv="$2" ;;
                --versions) version_csv="$2" ;;
                --progress) progress="$2" ;;
            esac
            shift 2 ;;
        --dry-run) dry_run=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown argument: $1" ;;
    esac
done

[[ "$namespace" =~ ^[a-z0-9][a-z0-9_-]*$ ]] ||
    die "Set --namespace or DOCKERHUB_NAMESPACE to a lowercase Docker Hub namespace"
case "$progress" in auto|plain|tty) ;; *) die "Invalid progress mode: $progress" ;; esac
case "$verify_remote" in true|false) ;; *) die "VERIFY_REMOTE must be true or false" ;; esac

# Reject malformed lists rather than silently discarding empty entries.
for csv in "$platform_csv" "$group_csv" "$variant_csv" "$version_csv"; do
    [[ -n "$csv" && "$csv" != ,* && "$csv" != *, && "$csv" != *,,* ]] ||
        die "Lists must contain nonempty comma-separated values"
done
IFS=, read -r -a platform_items <<< "$platform_csv"
platforms=""
for index in "${!platform_items[@]}"; do
    item="${platform_items[$index]}"
    case "$item" in
        amd64|x86_64|linux/amd64) item=linux/amd64 ;;
        arm64|aarch64|linux/arm64|linux/aarch64) item=linux/arm64 ;;
        *) die "Unsupported platform: $item (use amd64 or arm64/aarch64)" ;;
    esac
    case ",$platforms," in *",$item,"*) die "Duplicate platform: $item" ;; esac
    platform_items[index]="$item"
    platforms="${platforms:+$platforms,}$item"
done
IFS=, read -r -a groups <<< "$group_csv"
IFS=, read -r -a variants <<< "$variant_csv"
IFS=, read -r -a versions <<< "$version_csv"

validate_list() {
    local kind="$1" seen="" item
    shift
    for item in "$@"; do
        case "$kind:$item" in
            group:k8s|group:docker|variant:scratch|variant:alpine|version:[1-6]) ;;
            *) die "Invalid $kind: $item" ;;
        esac
        case ",$seen," in *",$item,"*) die "Duplicate $kind: $item" ;; esac
        seen="${seen:+$seen,}$item"
    done
}
validate_list group "${groups[@]}"
validate_list variant "${variants[@]}"
validate_list version "${versions[@]}"

# These globals define one matrix entry; the build and push loops share them.
select_image() {
    local group="$1" variant="$2" version="$3"
    case "$group" in
        k8s) image_group=kubernetes; repository=k8s-demo ;;
        docker) image_group=docker; repository=docker-demo ;;
    esac
    case "$version" in
        1) colour=blue ;; 2) colour=green ;; 3) colour=red ;;
        4) colour=cyan ;; 5) colour=yellow ;; 6) colour=white ;;
    esac
    tag="$version"
    runtime_image=scratch
    if [[ "$variant" == alpine ]]; then
        tag="alpine$version"
        runtime_image="$alpine_image"
    fi
    image="docker.io/$namespace/$repository:$tag"
    picture="static/img.$image_group/${image_group}_$colour"
}

platform_tag() {
    local base="$1" platform="$2"
    printf '%s-%s\n' "$base" "${platform##*/}"
}

run_command() {
    if "$dry_run"; then
        printf '%q ' "$@"
        printf '\n'
    else
        "$@"
    fi
}

if [[ "$action" == login ]]; then
    username="${DOCKERHUB_USERNAME:-$namespace}"
    if "$dry_run"; then
        run_command finch login --username "$username" docker.io
    else
        command -v finch >/dev/null 2>&1 || die "Finch is not installed"
        if [[ -n "${DOCKERHUB_TOKEN:-}" ]]; then
            printf '%s' "$DOCKERHUB_TOKEN" |
                finch login --username "$username" --password-stdin docker.io
        else
            finch login --username "$username" docker.io
        fi
        if ((${#platform_items[@]} > 1)); then
            command -v "$regctl_bin" >/dev/null 2>&1 ||
                die "regctl is required for multi-platform indexes; install it or set REGCTL_BIN"
            if [[ -n "${DOCKERHUB_TOKEN:-}" ]]; then
                printf '%s' "$DOCKERHUB_TOKEN" |
                    "$regctl_bin" registry login docker.io --user "$username" --pass-stdin
            else
                "$regctl_bin" registry login docker.io --user "$username"
            fi
        fi
    fi
    exit 0
fi

# Check the complete asset matrix before any builds or pushes start.
for group in "${groups[@]}"; do
    for variant in "${variants[@]}"; do
        for version in "${versions[@]}"; do
            select_image "$group" "$variant" "$version"
            for extension in txt png; do
                [[ -f "$project_dir/$picture.$extension" ]] ||
                    die "Missing demo asset: $picture.$extension"
            done
        done
    done
done

if ! "$dry_run"; then
    command -v finch >/dev/null 2>&1 || die "Finch is not installed"
    finch info >/dev/null || die "Finch is not ready; run 'finch vm init' (first use) or 'finch vm start'"
    if [[ "$action" == push || "$action" == build-push ]] &&
        ((${#platform_items[@]} > 1)); then
        command -v "$regctl_bin" >/dev/null 2>&1 ||
            die "regctl is required for multi-platform indexes; install it or set REGCTL_BIN"
    fi
fi

if [[ "$action" == build || "$action" == build-push ]]; then
    for group in "${groups[@]}"; do
        for variant in "${variants[@]}"; do
            for version in "${versions[@]}"; do
                select_image "$group" "$variant" "$version"
                for platform in "${platform_items[@]}"; do
                    platform_tag_name="$(platform_tag "$image" "$platform")"
                    printf 'Build %s [%s]\n' "$platform_tag_name" "$platform"
                    run_command finch build \
                        --platform "$platform" \
                        --progress "$progress" \
                        --file "$project_dir/Dockerfile" \
                        --tag "$platform_tag_name" \
                        --build-arg "GO_IMAGE=$go_image" \
                        --build-arg "RUNTIME_IMAGE=$runtime_image" \
                        --build-arg "IMAGE_GROUP=$image_group" \
                        --build-arg "IMAGE_NAME_VERSION=$image" \
                        --build-arg "IMAGE_VERSION=$version" \
                        --build-arg "PICTURE_COLOUR=$colour" \
                        --build-arg "PICTURE_PATH_BASE=$picture" \
                        --build-arg "DATE_VERSION=$build_date" \
                        --build-arg "BUILD_INFO=$build_info" \
                        --build-arg "SOURCE_REVISION=$source_revision" \
                        --build-arg "SOURCE_URL=$source_url" \
                        "$project_dir"
                done
            done
        done
    done
fi

if [[ "$action" == push || "$action" == build-push ]]; then
    for group in "${groups[@]}"; do
        for variant in "${variants[@]}"; do
            for version in "${versions[@]}"; do
                select_image "$group" "$variant" "$version"
                if ((${#platform_items[@]} == 1)); then
                    platform="${platform_items[0]}"
                    platform_tag_name="$(platform_tag "$image" "$platform")"
                    printf 'Push %s as %s [%s]\n' "$platform_tag_name" "$image" "$platform"
                    run_command finch tag "$platform_tag_name" "$image"
                    run_command finch push --platform "$platform" "$image"
                else
                    refs=()
                    printf 'Push per-platform manifests for %s [%s]\n' "$image" "$platforms"
                    for platform in "${platform_items[@]}"; do
                        platform_tag_name="$(platform_tag "$image" "$platform")"
                        refs+=("$platform_tag_name")
                        run_command finch push --platform "$platform" "$platform_tag_name"
                    done
                    printf 'Create Docker Hub OCI index %s\n' "$image"
                    regctl_args=(index create "$image")
                    for index in "${!platform_items[@]}"; do
                        regctl_args+=(--ref "${refs[$index]}" --platform "${platform_items[$index]}")
                    done
                    run_command "$regctl_bin" "${regctl_args[@]}"
                    if [[ "$verify_remote" == true ]]; then
                        for platform in "${platform_items[@]}"; do
                            printf 'Verify %s contains %s\n' "$image" "$platform"
                            run_command "$regctl_bin" manifest get "$image" \
                                --platform "$platform" --format raw-body >/dev/null
                        done
                    fi
                fi
            done
        done
    done
fi
printf 'Done: %s\n' "$action"
