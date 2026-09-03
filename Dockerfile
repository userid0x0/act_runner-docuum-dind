ARG GITEA_RUNNER_DIND_IMAGE=gitea-runner-dind

# use these hardcoded versions allow a proper detection by dependabot
FROM ghcr.io/linuxserver/baseimage-alpine:3.24 AS baseimage-alpine
FROM docker.io/gitea/runner:3.3.2-dind AS gitea-runner-dind
FROM ghcr.io/linuxserver/mods:universal-docker-in-docker-29.7.2-5.5.1 AS docker-in-docker-mod

# ---

FROM baseimage-alpine AS downloader-amd64

ARG DOCUUM_VERSION=0.27.0

ADD --chown=root:root \
    --chmod=755 \
    https://github.com/stepchowfun/docuum/releases/download/v${DOCUUM_VERSION}/docuum-x86_64-unknown-linux-musl \
    /patch/usr/local/bin/docuum

FROM baseimage-alpine AS downloader-arm64

ARG DOCUUM_VERSION=0.27.0

ADD --chown=root:root \
    --chmod=755 \
    https://github.com/stepchowfun/docuum/releases/download/v${DOCUUM_VERSION}/docuum-aarch64-unknown-linux-musl \
    /patch/usr/local/bin/docuum

FROM downloader-${TARGETARCH} AS downloader

# use this indirection in order to have a override capability e.g. for nightly / local gitea-runner builds
FROM ${GITEA_RUNNER_DIND_IMAGE} AS downloader-gitea-runner

# prepare /patch with gitea-runner & run.sh
# ensure run.sh uses `/config` as LSIO does
RUN mkdir -p /patch/usr/local/bin \
    && cp /usr/local/bin/gitea-runner /patch/usr/local/bin/gitea-runner

# ---

FROM baseimage-alpine AS runner

# <universal-docker-in-docker>
# add a DOCKER_MOD universal-docker-in-docker as a static mod
# - docker itself will the installed on container start
# - speedup - install dependencies already using apk
# - use /data as persistent docker storage
COPY --from=docker-in-docker-mod / /mods/universal-docker-in-docker-29

ENV DOCKER_MODS=universal-docker-in-docker-29 \
    DOCKER_MODS_SIDELOAD=true \
    MODS_DIND_PERSISTENCE=/data/var/lib/docker \
    S6_STAGE2_HOOK=/dynamic-svc-gitea-runner

RUN apk add --no-cache \
      btrfs-progs \
      curl \
      e2fsprogs \
      e2fsprogs-extra \
      ip6tables \
      iptables \
      openssl \
      pigz \
      xfsprogs \
      xz \
    && mkdir -p /data/var/lib/docker

VOLUME [ "/data" ]
# </universal-docker-in-docker>

# install
# - docuum
# - gitea-runner
COPY --from=downloader /patch /
COPY --from=downloader-gitea-runner /patch /

# add local configuration and s6-rc.d logic
ADD /root-runner /

# ---

FROM baseimage-alpine AS cache

# storage location of the cache
VOLUME [ "/data" ]
# default port for the cache server
EXPOSE 8080

# install
# - gitea-runner
COPY --from=downloader-gitea-runner /patch /

# add local configuration and s6-rc.d logic
ADD /root-cache /
ADD /root-runner/opt/lib /opt/lib