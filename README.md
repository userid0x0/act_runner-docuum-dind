[![Docker Image](https://img.shields.io/badge/Docker%20Image-available-success&style=flat)](https://hub.docker.com/r/userid0x0/act_runner-docuum-dind/)
[![Build](https://img.shields.io/github/actions/workflow/status/userid0x0/act_runner-docuum-dind/docker-build-publish.yml?branch=master&label=build&logo=github&style=flat)](https://github.com/userid0x0/act_runner-docuum-dind/actions)

# Gitea act_runner with docuum - Docker-in-Docker (dind) variant

## Intention
A `act_runner` Image with S6 Version 3 that manages:

* `docker` as Docker-in-Docker/dind
* `act_runner`
* `docuum`

with a `linuxserver.io` insprired usage. Persistent files are stored in `/data` reducing the number of bind-mounts.

## Usage

### `docker-compose.yml`
```yaml
services:
  runner:
    image: docker.io/userid0x0/act_runner-docuum-dind:0.2.13-1
    restart: unless-stopped
    privileged: true
    environment:
      GITEA_INSTANCE_URL: "${INSTANCE_URL}"
      GITEA_RUNNER_REGISTRATION_TOKEN: "${REGISTRATION_TOKEN}"
      GITEA_RUNNER_NAME: "${RUNNER_NAME}"
      # DOCUUM_ARGS: "--threshold 80GB"
    env_file:
      - .env
    volumes:
      - ./data:/data
      - docker:/var/lib/docker

volumes:
  docker:
```

### `.env`
```
INSTANCE_URL=https://<...>
REGISTRATION_TOKEN=<...>
RUNNER_NAME=<...>
```