[![Docker Image](https://img.shields.io/badge/Docker%20Image-available-success&style=flat)](https://hub.docker.com/r/userid0x0/act_runner-docuum-dind/)
[![Build](https://img.shields.io/github/actions/workflow/status/userid0x0/act_runner-docuum-dind/docker-build-publish.yml?branch=master&label=build&logo=github&style=flat)](https://github.com/userid0x0/act_runner-docuum-dind/actions)

# Gitea act_runner with docuum - Docker-in-Docker (DinD) variant

## Intention
A [act_runner](https://gitea.com/gitea/act_runner) Image based on [linuxserver.io](https://linuxserver.io)'s `baseimage-alpine`. Included components:

* `docker` as Docker-in-Docker (DinD)<br> installed via a local `DOCKER_MOD`
* `act_runner`
* `docuum` for LRU based Docker Image cleanup

Persistent files are stored in `/config` reducing the number of bind-mounts. Services are run as user `abc`.

## Usage

### `docker-compose.yml`
```yaml
services:
  runner:
    image: docker.io/userid0x0/act_runner-docuum-dind:0.2.13-1
    restart: unless-stopped
    privileged: true
    environment:
      PUID: <uid to use>
      PGID: <gid to use>
      GITEA_INSTANCE_URL: "${INSTANCE_URL}"
      GITEA_RUNNER_REGISTRATION_TOKEN: "${REGISTRATION_TOKEN}"
      GITEA_RUNNER_NAME: "${RUNNER_NAME}"
      # DOCUUM_ARGS: "--threshold 80GB"
    env_file:
      - .env
    volumes:
      - ./config:/config
      - docker:/config/var/lib/docker

volumes:
  docker:
```

### `.env`
```
INSTANCE_URL=https://<...>
REGISTRATION_TOKEN=<...>
RUNNER_NAME=<...>
```

## Adaptions/Modifications
### Environment Variables

* `PUID`/`PGID` - UID to use for services e.g. act_runner/docuum<br>This the is UID/GID of the files in `/config`<br> default: `911`
* `DOCUUM_ARGS` - command line arguments passed to docuum e.g. Image storage threshold, persistent images, ...<br>default `--threshold 80GB`

### `/custom-cont-init.d`
Based on https://docs.linuxserver.io/general/container-customization/#custom-scripts the image can be adapted to local requirements. Usage e.g.

* custom root certificate installation
* configuration changes e.g. `/etc/docker/daemon.json`

## Internals
### s6rc.d dependency graph
![s6rc.d dependency](/misc/s6rc.svg)

