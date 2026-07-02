FROM ghcr.io/linuxserver/baseimage-alpine:3.24 AS baseimage-alpine
FROM docker.io/gitea/runner:2.0.0-dind AS gitea-runner-dind

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

FROM gitea-runner-dind AS downloader-gitea-runner

# prepare /patch with gitea-runner & run.sh
# ensure run.sh uses `/config` as LSIO does
RUN mkdir -p /patch/usr/local/bin \
    && cp /usr/local/bin/run.sh       /patch/usr/local/bin/run-gitea-runner.sh \
    && cp /usr/local/bin/gitea-runner /patch/usr/local/bin/gitea-runner \
    && sed -i 's# /data# /config#'    /patch/usr/local/bin/run-gitea-runner.sh

# ---

FROM baseimage-alpine

# <universal-docker-in-docker>
# add a DOCKER_MOD universal-docker-in-docker as a static mod
# - docker itself will the installed on container start
# - speedup - install dependencies already using apk
# - use /data as persistent docker storage
COPY --from=ghcr.io/linuxserver/mods:universal-docker-in-docker-28.5.2-2.40.3 / /mods/universal-docker-in-docker-28
COPY --from=ghcr.io/linuxserver/mods:universal-docker-in-docker-29.5.3-5.1.4 / /mods/universal-docker-in-docker-29

ENV DOCKER_MODS=universal-docker-in-docker-29 \
    DOCKER_MODS_SIDELOAD=true \
    MODS_DIND_PERSISTENCE=/data/var/lib/docker

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
# - gitea-runner (including some scripts)
COPY --from=downloader /patch /
COPY --from=downloader-gitea-runner /patch /

# add local configuration and s6-rc.d logic
ADD /root /

