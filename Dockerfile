ARG TAG=0.2.13

FROM docker.io/gitea/act_runner:${TAG}-dind AS downloader-amd64

ARG S6_OVERLAY_VERSION=3.2.1.0
ARG DOCUUM_VERSION=0.25.1

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp/s6-overlay-arch.tar.xz
RUN mkdir /patch \
    && tar -C /patch -Jxpf /tmp/s6-overlay-noarch.tar.xz \
    && tar -C /patch -Jxpf /tmp/s6-overlay-arch.tar.xz

ADD --chown=root:root \
    --chmod=755 \
    https://github.com/stepchowfun/docuum/releases/download/v${DOCUUM_VERSION}/docuum-x86_64-unknown-linux-musl \
    /patch/usr/local/bin/docuum

FROM docker.io/gitea/act_runner:${TAG}-dind AS downloader-arm64

ARG S6_OVERLAY_VERSION=3.2.1.0
ARG DOCUUM_VERSION=0.25.1

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-aarch64.tar.xz /tmp/s6-overlay-arch.tar.xz
RUN mkdir /patch \
    && tar -C /patch -Jxpf /tmp/s6-overlay-noarch.tar.xz \
    && tar -C /patch -Jxpf /tmp/s6-overlay-arch.tar.xz

ADD --chown=root:root \
    --chmod=755 \
    https://github.com/stepchowfun/docuum/releases/download/v${DOCUUM_VERSION}/docuum-aarch64-unknown-linux-musl \
    /patch/usr/local/bin/docuum

FROM downloader-${TARGETARCH} AS downloader

FROM docker.io/gitea/act_runner:${TAG}-dind

RUN apk del s6 \
    && rm -rf /etc/s6

COPY --from=downloader /patch /
ADD /root /

RUN mkdir -p /data

ENTRYPOINT [ "/init" ]