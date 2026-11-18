#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$project_dir/.build"
test_dir="$(mktemp -d "$project_dir/.build/command-tests.XXXXXX")"
export FINCH_TEST_LOG="$test_dir/finch.log"
export PATH="$project_dir/tests/fixtures:$PATH"
export REGCTL_BIN=regctl
unset FINCH_TEST_FAIL DOCKERHUB_NAMESPACE DOCKERHUB_TOKEN DOCKERHUB_USERNAME
unset PLATFORMS GROUPS_TO_BUILD VARIANTS VERSIONS PROGRESS
script="$project_dir/simple-build.sh"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
clear_log() { : > "$FINCH_TEST_LOG"; }
count_command() { awk -F '|' -v command="$1" '$1 == command {n++} END {print n+0}' "$FINCH_TEST_LOG"; }
expect_count() {
    [[ "$(count_command "$1")" == "$2" ]] || fail "Expected $2 $1 commands"
}
expect_failure() {
    if bash "$script" "$@" > "$test_dir/output" 2>&1; then
        fail "Invalid arguments succeeded: $*"
    fi
}

bash "$script" --help >/dev/null
clear_log
bash "$script" build --namespace testuser > "$test_dir/output"
expect_count build 48
expect_count push 0
expect_count login 0
expect_count regctl 0
grep -Fq -- '--platform|linux/amd64|' "$FINCH_TEST_LOG" || fail 'Missing amd64 platform flag'
grep -Fq -- '--platform|linux/arm64|' "$FINCH_TEST_LOG" || fail 'Missing arm64 platform flag'
for repo in k8s-demo docker-demo; do
    for tag in 1 2 3 4 5 6 alpine1 alpine2 alpine3 alpine4 alpine5 alpine6; do
        grep -Fq -- "--tag|docker.io/testuser/$repo:$tag-amd64|" "$FINCH_TEST_LOG" || fail "Missing $repo:$tag-amd64"
        grep -Fq -- "--tag|docker.io/testuser/$repo:$tag-arm64|" "$FINCH_TEST_LOG" || fail "Missing $repo:$tag-arm64"
    done
done
printf 'PASS default 24-tag/two-platform build matrix and no implicit push/login\n'

clear_log
# Deliberately invoke from outside the project; each argument remains a separate word.
(
    cd "$test_dir"
    BUILD_INFO='100% & "quotes" ? slashes / $literal' bash "$script" build-push \
        --namespace testuser --groups k8s --variants scratch --versions 1 \
        --platforms amd64,aarch64 > output
)
expect_count build 2
expect_count push 2
expect_count regctl 3
# shellcheck disable=SC2016 # Assert a literal dollar sign, not variable expansion.
grep -Fq -- 'BUILD_INFO=100% & "quotes" ? slashes / $literal|' "$FINCH_TEST_LOG" || fail 'Metadata quoting'
grep -Fq -- 'push|--platform|linux/amd64|docker.io/testuser/k8s-demo:1-amd64|' "$FINCH_TEST_LOG" ||
    fail 'AMD64 push missing'
grep -Fq -- 'push|--platform|linux/arm64|docker.io/testuser/k8s-demo:1-arm64|' "$FINCH_TEST_LOG" ||
    fail 'ARM64 push missing'
grep -Fq -- 'regctl|index|create|docker.io/testuser/k8s-demo:1|--ref|docker.io/testuser/k8s-demo:1-amd64|--platform|linux/amd64|--ref|docker.io/testuser/k8s-demo:1-arm64|--platform|linux/arm64|' "$FINCH_TEST_LOG" ||
    fail 'OCI index assembly missing'
printf 'PASS aliases, argument quoting, external working directory, per-platform push, OCI index assembly\n'

clear_log
bash "$script" build-push --namespace testuser > "$test_dir/output"
expect_count build 48
expect_count push 48
expect_count regctl 72
awk -F '|' '$1=="push" {pushed=1} $1=="build" && pushed {exit 1}' "$FINCH_TEST_LOG" ||
    fail 'Build occurred after publishing started'
printf 'PASS all builds complete before publishing starts\n'

clear_log
export FINCH_TEST_FAIL=build
expect_failure build-push --namespace testuser
expect_count push 0
expect_count regctl 0
unset FINCH_TEST_FAIL
export FINCH_TEST_FAIL=info
expect_failure build --namespace testuser
expect_count push 0
unset FINCH_TEST_FAIL
printf 'PASS failures stop publishing\n'

clear_log
bash "$script" -push --namespace testuser --groups docker --variants alpine --versions 2 > "$test_dir/output"
expect_count build 0
expect_count push 2
expect_count regctl 3
printf 'PASS push-only/legacy -push with matching filters\n'

clear_log
bash "$script" build-push --namespace testuser --dry-run > "$test_dir/output"
[[ ! -s "$FINCH_TEST_LOG" ]] || fail 'Dry run invoked Finch'
grep -Fq 'finch push --platform linux/amd64' "$test_dir/output" || fail 'Dry-run amd64 push missing'
grep -Fq 'regctl index create' "$test_dir/output" || fail 'Dry-run index missing'
printf 'PASS dry run has no Finch side effects\n'

clear_log
for args in \
    '--namespace' '--namespace UPPERCASE' '--namespace bad/user' \
    '--namespace testuser --groups tf' '--namespace testuser --variants dynamic' \
    '--namespace testuser --versions 0' '--namespace testuser --versions 1,' \
    '--namespace testuser --versions 1,1' '--namespace testuser --platforms arm64,aarch64' \
    '--namespace testuser --platforms linux/s390x' '--namespace testuser --unknown' '-rmi'; do
    # These cases deliberately contain simple whitespace-delimited argument tokens.
    read -r -a invalid_args <<< "$args"
    expect_failure "${invalid_args[@]}"
done
expect_failure build
[[ ! -s "$FINCH_TEST_LOG" ]] || fail 'Invalid args invoked Finch'
printf 'PASS invalid inputs fail before contacting Finch\n'

clear_log
DOCKERHUB_USERNAME=loginuser DOCKERHUB_TOKEN='test-only-secret' FINCH_TEST_EXPECT_TOKEN='test-only-secret' \
    bash "$script" login --namespace team > "$test_dir/output"
expect_count login 1
expect_count regctl 1
grep -Fq 'login|--username|loginuser|--password-stdin|docker.io|' "$FINCH_TEST_LOG" || fail 'Login argv'
grep -Fq 'regctl|registry|login|docker.io|--user|loginuser|--pass-stdin|' "$FINCH_TEST_LOG" || fail 'regctl login argv'
if grep -Fq 'test-only-secret' "$FINCH_TEST_LOG" "$test_dir/output"; then
    fail 'Token leaked into output or argv'
fi
printf 'PASS token login uses stdin and separate organization username\n'
printf 'All command tests passed (mock Finch; no registry writes).\n'
