ARG ALPINE_TAG=3.22
ARG ACT_RUNNER_TAG=0.2.13

FROM ghcr.io/linuxserver/baseimage-alpine:${ALPINE_TAG} AS downloader-amd64

ARG DOCUUM_VERSION=0.25.1

ADD --chown=root:root \
    --chmod=755 \
    https://github.com/stepchowfun/docuum/releases/download/v${DOCUUM_VERSION}/docuum-x86_64-unknown-linux-musl \
    /patch/usr/local/bin/docuum

FROM ghcr.io/linuxserver/baseimage-alpine:${ALPINE_TAG} AS downloader-arm64

ARG DOCUUM_VERSION=0.25.1

ADD --chown=root:root \
    --chmod=755 \
    https://github.com/stepchowfun/docuum/releases/download/v${DOCUUM_VERSION}/docuum-aarch64-unknown-linux-musl \
    /patch/usr/local/bin/docuum

FROM downloader-${TARGETARCH} AS downloader
FROM docker.io/gitea/act_runner:${ACT_RUNNER_TAG}-dind AS act_runner

# prepare /patch with act_runner & run.sh
# ensure run.sh uses `/config` as LSIO does
RUN mkdir -p /patch/usr/local/bin \
    && cp /usr/local/bin/run.sh     /patch/usr/local/bin/run-act_runner.sh \
    && cp /usr/local/bin/act_runner /patch/usr/local/bin/act_runner \
    && sed -i 's# /data# /config#'  /patch/usr/local/bin/run-act_runner.sh

FROM ghcr.io/linuxserver/baseimage-alpine:${ALPINE_TAG}

# <universal-docker-in-docker>
# add a DOCKER_MOD universal-docker-in-docker as a static mod
# - docker itself will the installed on container start
# - speedup - install dependencies already using apk
COPY --from=ghcr.io/linuxserver/mods:universal-docker-in-docker-28.5.2-2.40.3 / /mods/universal-docker-in-docker

ENV DOCKER_MODS=universal-docker-in-docker \
    DOCKER_MODS_SIDELOAD=true

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
      xz
# </universal-docker-in-docker>

# install
# - docuum
# - act_runner (including some scripts)
COPY --from=downloader /patch /
COPY --from=act_runner /patch /

# add local configuration and s6-rc.d logic
ADD /root /

