#!/bin/bash
cat <<EOF > /tmp/config.yaml
cache:
  external_secret: ${GITEA_CACHE_SECRET}
EOF
gitea-runner cache-server -c /tmp/config.yaml -s ${GITEA_CACHE_HOSTNAME} -p ${GITEA_CACHE_PORT} -d /data/cache