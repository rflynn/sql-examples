#!/bin/bash

# ref: https://github.com/sameersbn/docker-postgresql

set -v

# ensure postgresql container running
docker run \
  --name postgresql \
  -itd \
  --publish 5432:5432 \
  --volume /srv/docker/postgresql:/var/lib/postgresql \
  sameersbn/postgresql:9.4-21

sleep 2

docker exec -i postgresql sudo -u postgres psql -a < /dev/stdin

docker stop postgresql
docker rm postgresql

