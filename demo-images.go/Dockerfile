# syntax=docker/dockerfile:1
# Override these with --build-arg. Use multi-platform index digests for strict pinning.
ARG GO_IMAGE=golang:1.27.4-alpine3.24
ARG RUNTIME_IMAGE=scratch

# Compile on the builder's native CPU, not the target CPU.
# hadolint ignore=DL3006
FROM --platform=$BUILDPLATFORM ${GO_IMAGE} AS build
WORKDIR /src
COPY go.mod main.build.go main_build_test.go ./
COPY templates/index.html.tmpl /src/templates/index.html.tmpl
ARG TARGETOS
ARG TARGETARCH
RUN --mount=type=cache,target=/root/.cache/go-build \
    go vet ./... && go test ./... && \
    CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath -ldflags="-s -w -buildid=" -o /out/demo-binary .

# The default is scratch; pass RUNTIME_IMAGE=alpine:3.24.4 for the shell variant.
# Do NOT execute the target binary here: that would require target CPU emulation.
# hadolint ignore=DL3006
FROM ${RUNTIME_IMAGE} AS runtime-image
WORKDIR /app
COPY --from=build /out/demo-binary /app/demo-binary
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY static/css/ /app/static/css/
COPY static/index.html /app/static/index.html
COPY templates/index.html.tmpl /app/templates/index.html.tmpl
ARG IMAGE_GROUP=kubernetes
COPY static/img.${IMAGE_GROUP}/ /app/static/img.${IMAGE_GROUP}/
# /map historically expects this shared path, regardless of logo group.
COPY static/img.kubernetes/mapascii.txt /app/static/img/mapascii.txt

ARG IMAGE_NAME_VERSION=local/demo:dev
ARG IMAGE_VERSION=dev
ARG PICTURE_COLOUR=blue
ARG PICTURE_PATH_BASE=static/img.kubernetes/kubernetes_blue
ARG DATE_VERSION=unknown
ARG BUILD_INFO="local build"
ARG SOURCE_REVISION=unknown
ARG SOURCE_URL=""
ENV IMAGE_NAME_VERSION=${IMAGE_NAME_VERSION} \
    IMAGE_VERSION=${IMAGE_VERSION} \
    PICTURE_COLOUR=${PICTURE_COLOUR} \
    PICTURE_PATH_BASE=${PICTURE_PATH_BASE} \
    DATE_VERSION=${DATE_VERSION} \
    BUILD_INFO=${BUILD_INFO}
LABEL org.opencontainers.image.title="demo-images" \
    org.opencontainers.image.description="Kubernetes and Docker demo HTTP server" \
    org.opencontainers.image.version=${IMAGE_VERSION} \
    org.opencontainers.image.created=${DATE_VERSION} \
    org.opencontainers.image.revision=${SOURCE_REVISION} \
    org.opencontainers.image.source=${SOURCE_URL}

# Preserve existing Kubernetes manifests expecting port 80.
EXPOSE 80
CMD ["/app/demo-binary", "-l", "80", "-L", "0", "-R", "0"]
