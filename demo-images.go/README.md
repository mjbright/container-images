# demo-images: Finch multi-architecture builds

Kubernetes/Docker demo HTTP server, preserving the original numbered demo images.
Build Linux AMD64 and ARM64 images with Finch and publish one Docker Hub tag per
demo variant as an OCI Image Index. `aarch64` is normalized to OCI `arm64`.

## Quick start on macOS

Install [Finch](https://runfinch.com/docs/getting-started/installing-finch/),
`regctl` (for example, `brew install regclient`), and initialize Finch's VM once:

```bash
brew install --cask finch
brew install regclient
finch vm init
# On subsequent sessions if stopped:
finch vm start
finch info
```

No local Go installation, Docker Desktop, or Buildx is needed. The script builds
one architecture at a time, pushes each architecture to a temporary suffixed
tag, then uses `regctl` to assemble and verify the final OCI index. `regctl` is
required for multi-platform publishing.

Set your Docker Hub user or organization. Nothing defaults to the original
`mjbright` account:

```bash
export DOCKERHUB_NAMESPACE=your-dockerhub-namespace
./simple-build.sh build-push --dry-run

# Start small: build one image tag for both architectures.
./simple-build.sh build --groups k8s --variants scratch --versions 1

# Test the local architecture-specific image tags. Non-native execution needs
# Finch's emulation support.
./scripts/test_docker_image.sh \
  "docker.io/$DOCKERHUB_NAMESPACE/k8s-demo:1-amd64" amd64
./scripts/test_docker_image.sh \
  "docker.io/$DOCKERHUB_NAMESPACE/k8s-demo:1-arm64" arm64

# Authenticate both Finch and regctl using a Docker Hub access token.
./simple-build.sh login

# Publish both per-architecture images and create/verify the shared OCI index.
./simple-build.sh push --groups k8s --variants scratch --versions 1
```

The scripts are Bash 3.2 compatible. If executable permission was lost while
unpacking, use `bash ./simple-build.sh ...` (or restore it with `chmod +x`).
Run from any directory: paths are resolved relative to the script.

To build and publish the entire original matrix:

```bash
./simple-build.sh build-push
```

That builds all 24 tags first (48 platform-specific image variants, tagged
`-amd64` and `-arm64`), then starts publishing. Only after both architecture
images are pushed does it create the unsuffixed public tag as an OCI index and
verify that the registry resolves it to both architectures. Build failures abort
before any push; later failures stop immediately. Publishing multiple tags is
not transactional: already-pushed architecture tags or final tags remain if a
later operation fails. Rebuilding these numbered tags replaces their prior
content on Docker Hub. No automatic `latest` tag is created.

## Image matrix and filters

| Group | Repository | Scratch tags | Alpine tags |
| --- | --- | --- | --- |
| `k8s` | `k8s-demo` | `1`–`6` | `alpine1`–`alpine6` |
| `docker` | `docker-demo` | `1`–`6` | `alpine1`–`alpine6` |

Colours: 1 blue, 2 green, 3 red, 4 cyan, 5 yellow, 6 white.
The original Terraform group was disabled, and its asset set lacks the matching
PNG matrix; it remains excluded rather than publishing broken demos.

Both variants use the **same statically linked Go binary**. Alpine adds a shell
and its base utilities; the old "dynamic" label was misleading because it also
used `CGO_ENABLED=0`.

```bash
./simple-build.sh build --namespace example \
  --platforms amd64,aarch64 \
  --groups docker --variants alpine --versions 2,3
./simple-build.sh push --namespace example \
  --platforms amd64,aarch64 \
  --groups docker --variants alpine --versions 2,3
```

Use the same namespace, platform, and matrix filters for build and push.
`build` creates local per-platform tags such as `:alpine2-amd64` and
`:alpine2-arm64`; it does not publish. `push` publishes those existing local
images, then creates the unsuffixed final tag (such as `:alpine2`) as the OCI
index. It does not rebuild. If an architecture-specific image is missing locally
or remotely, the command stops instead of manufacturing an index entry.

Defaults can be overridden by `PLATFORMS`, `GROUPS_TO_BUILD`, `VARIANTS`, `VERSIONS`,
and `PROGRESS`. Command-line options take precedence. Lists are comma-separated
without spaces; empty, duplicate, and unsupported values are rejected.

## Docker Hub authentication

The namespace must exist, and the login user needs write access to `k8s-demo`
and/or `docker-demo` repositories. For multi-platform publishing, `login` stores
credentials for both Finch and `regctl`. For organizations:

```bash
export DOCKERHUB_NAMESPACE=your-organization
export DOCKERHUB_USERNAME=your-personal-login
./simple-build.sh login
```

For CI, inject `DOCKERHUB_TOKEN` through your secret manager and run `login`.
The script passes it to both login commands via stdin, never in command
arguments or its own logs. Do not commit credentials or use `bash -x` while
logging in. Build and push never perform an implicit login. If you already logged
in to Finch, run `regctl registry login docker.io --user "$DOCKERHUB_USERNAME"`
separately (use `--pass-stdin` for a token) before publishing.

Finch documentation:
[building images](https://runfinch.com/docs/getting-started/building-images/) and
[pushing images](https://runfinch.com/docs/getting-started/pushing-images/).

## Dockerfile design

`Dockerfile` replaces the sed-generated `templates/Dockerfile.tmpl`, which now
contains only a retirement notice. The script does not overwrite Dockerfile.

- Builder is explicitly `--platform=$BUILDPLATFORM`; native `go vet` and `go test`
  run there, then `CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH` cross-compiles.
- No target binary is executed in the final stage, avoiding emulation during
  builds. Running/testing the non-native image still needs Finch's translation
  or emulation support.
- Source and tests are copied before build metadata/assets, improving cache
  reuse. Go's compilation cache uses a BuildKit cache mount.
- `COPY`, not `ADD`, is used. Only the selected logo group, CSS, index, HTML
  template, map, binary, and CA certificates reach the final image.
- `.dockerignore` excludes credentials, Git data, scripts, and local binaries.
- OCI labels and original image/environment metadata are retained. Metadata uses
  real build arguments, so shell/sed delimiters and quotes are not substituted
  into a generated instruction.
- Port 80 and the original exec-form command are preserved for existing demos.
  The scratch image has no shell. Alpine permits a command override such as
  `finch run --rm -it IMAGE /bin/sh`.

Base defaults, verified in the official Docker image catalogue on 2026-11-16:
`golang:1.27.4-alpine3.24` and `alpine:3.24.4`. Override with `GO_IMAGE` and
`ALPINE_IMAGE`. For stricter reproducibility set them to **multi-platform index
digests**, not a single-architecture manifest digest, and provide a fixed
`DATE_VERSION`. `BUILD_INFO`, `SOURCE_REVISION`, and `SOURCE_URL` are optional
build metadata. Metadata intentionally does not collect your username, hostname,
public IP, or potentially credential-bearing Git remote URL.

Avoid pushing a single Finch multi-platform build directly to the final tag when
publishing this project. The supported script path keeps each pushed manifest
explicitly associated with its architecture and verifies the final index.
`VERIFY_REMOTE=false` disables the registry check only when necessary; the
default is to fail unless both architecture lookups succeed.

## Validation

Command regression tests use a fake Finch executable; they never publish:

```bash
bash tests/test-build.sh
bash -n simple-build.sh scripts/*.sh tests/test-build.sh tests/fixtures/finch
# Optional local Go checks; they also run inside the container builder:
go vet ./...
go test ./...
```

After pushing, force pulls the final OCI index from Docker Hub and checks each
returned binary's architecture plus `/version`, `/ping`, and the served PNG:

```bash
PULL_POLICY=always ./scripts/test_docker_image.sh \
  "docker.io/$DOCKERHUB_NAMESPACE/k8s-demo:1" amd64,aarch64
```

The test binds to loopback, has bounded readiness polling, and removes only the
container ID it created. Change the third argument for a different local port.
For a native-only run, pass `arm64` on Apple Silicon or `amd64` on Intel.
To examine the remote image index without running it, use Docker Hub's image
details or, if separately installed:

```bash
docker buildx imagetools inspect \
  "docker.io/$DOCKERHUB_NAMESPACE/k8s-demo:1"
```

It must list `linux/amd64` and `linux/arm64`. That inspection command is optional;
Docker/Buildx is not otherwise required.

The updated Kubernetes helper uses modern `kubectl run` and `kubectl wait`,
forces a registry pull, then forwards port 80. It creates one temporary pod in
your currently selected cluster and removes only that pod on exit:

```bash
./scripts/kubetest_docker_image.sh \
  "docker.io/$DOCKERHUB_NAMESPACE/k8s-demo:1" 18080 default
```

Private Docker Hub repositories need Kubernetes `imagePullSecrets`.
Run the published image on native AMD64 and ARM64 nodes/runners for final
architecture-sensitive release validation.

## Review scope

The original upload had a `.go` name but was a ZIP archive. All original static
assets and the HTML appearance are preserved. Nonconstant-format-string
output bugs were fixed so modern `go vet` passes and literal `%` text renders
correctly; `/version` and `--version` now report the binary platform.
The broken local testmode logo and `/map` asset paths are fixed.

Legacy `-push` aliases `push`. The `-run`, `-test`, `-stop`, `-rm`, and `-rmi`
actions are explicitly rejected: they used fixed names/accounts and broad
container deletion or image pruning. Use the scoped smoke helper instead.

This is still a **demo server**, not a production-hardening rewrite: global
request counters/flags can race under concurrent requests, outbound-IP lookup
can terminate a request process on network errors, and port 80/root defaults
remain for compatibility. A separate runtime hardening pass is recommended if
you expose it beyond a controlled demonstration environment.
