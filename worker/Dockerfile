# syntax=docker/dockerfile:1
# 015 worker image — build context MUST be repository root
#   docker build -f worker/Dockerfile -t 015-worker .

FROM golang:1.25.5 AS builder
WORKDIR /app
ARG GOPROXY=https://proxy.golang.org,https://goproxy.cn,direct
ENV GO111MODULE=on \
    GOPROXY=${GOPROXY} \
    CGO_ENABLED=0 \
    GOOS=linux
COPY go.work go.work.sum ./
COPY backend/ ./backend/
COPY worker/ ./worker/
COPY pkg/ ./pkg/
RUN go mod download
RUN go build -trimpath -ldflags="-s -w" -o /out/worker-bin ./worker

FROM alpine:3.21
ARG VERSION=dev
ARG BUILD_TIME=unknown
ARG REVISION=unknown

LABEL org.opencontainers.image.title="015-worker" \
      org.opencontainers.image.description="015 async worker (image compress / convert queue)" \
      org.opencontainers.image.source="https://github.com/witguang/015" \
      org.opencontainers.image.url="https://github.com/witguang/015" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.created="${BUILD_TIME}" \
      org.opencontainers.image.licenses="AGPL-3.0" \
      org.opencontainers.image.vendor="witguang"

RUN apk add --no-cache \
        ca-certificates \
        pngquant \
        jpegoptim \
        imagemagick \
        tini \
        procps \
    && update-ca-certificates

COPY --from=builder /out/worker-bin /bin/worker
RUN chmod 755 /bin/worker

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD pgrep -x worker >/dev/null || exit 1

# tini 作为 PID 1，正确回收僵尸进程（商用必备）
ENTRYPOINT ["/sbin/tini", "--", "/bin/worker"]
