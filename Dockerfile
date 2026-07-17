# syntax=docker/dockerfile:1
# 015 app image — optimized for GitHub Actions / GHCR (layer cache + multi-stage)

FROM node:22-alpine AS front-base
WORKDIR /app
RUN corepack enable pnpm

# ---------------------------------------------------------------------------
# 1) Frontend dependency layer (cached unless lockfiles change)
# ---------------------------------------------------------------------------
FROM front-base AS front-deps
RUN apk add --no-cache gcompat
ENV CI=true
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY front/package.json ./front/
COPY pkg/mail/package.json ./pkg/mail/
# frozen-lockfile 保证 CI 可复现；失败时便于发现 lock 未更新
RUN pnpm i --frozen-lockfile

# ---------------------------------------------------------------------------
# 2) Frontend + mail templates build
# ---------------------------------------------------------------------------
FROM front-deps AS front-builder
ENV NODE_OPTIONS="--max-old-space-size=4096"
COPY . .
RUN pnpm --filter=015-front build && pnpm --dir pkg/mail export

# ---------------------------------------------------------------------------
# 3) Backend Go build
# ---------------------------------------------------------------------------
FROM golang:1.26.3 AS backend-builder
WORKDIR /app
# GitHub Actions 优先用官方代理；国内构建可 --build-arg GOPROXY=https://goproxy.cn,direct
ARG GOPROXY=https://proxy.golang.org,https://goproxy.cn,direct
ENV GO111MODULE=on \
    GOPROXY=${GOPROXY} \
    CGO_ENABLED=0 \
    GOOS=linux
COPY go.work go.work.sum ./
COPY backend/ ./backend/
COPY worker/ ./worker/
COPY pkg/ ./pkg/
COPY --from=front-builder /app/pkg/mail/out/ ./pkg/mail/out/
RUN go mod download
RUN go build -trimpath -ldflags="-s -w" -o /out/backend-bin ./backend

# ---------------------------------------------------------------------------
# 4) Runtime
# ---------------------------------------------------------------------------
FROM front-base AS runner
ARG VERSION=dev
ARG BUILD_TIME=unknown
ARG REVISION=unknown

LABEL org.opencontainers.image.title="015" \
      org.opencontainers.image.description="Self-hosted temporary file sharing platform" \
      org.opencontainers.image.source="https://github.com/witguang/015" \
      org.opencontainers.image.url="https://github.com/witguang/015" \
      org.opencontainers.image.documentation="https://github.com/witguang/015" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.created="${BUILD_TIME}" \
      org.opencontainers.image.licenses="AGPL-3.0" \
      org.opencontainers.image.vendor="witguang"

RUN apk add --no-cache curl openssl \
    && addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 nuxtjs

COPY --from=front-builder --chown=nuxtjs:nodejs /app/front/.output/ ./
COPY --from=backend-builder /out/backend-bin /bin/backend
COPY 015.sh /app/015.sh
RUN chmod 755 /app/015.sh /bin/backend

ENV NODE_ENV=production \
    PORT=80 \
    HOST=0.0.0.0 \
    VERSION=${VERSION} \
    BUILD_TIME=${BUILD_TIME}

EXPOSE 80

# 商用探活：compose / k8s / 编排器可依赖此检查
HEALTHCHECK --interval=30s --timeout=5s --start-period=45s --retries=3 \
    CMD curl -fsS http://127.0.0.1:80/ >/dev/null || exit 1

CMD ["/bin/sh", "/app/015.sh"]
