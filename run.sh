#!/bin/bash

# ref: https://github.com/sameersbn/docker-postgresql

set -o xtrace
set -o errexit
set -o pipefail


cleanup() {
    docker stop postgresql
}
trap cleanup EXIT

which docker-machine && eval $(docker-machine env)
docker-machine ip default # ensure this doesn't crash

docker run \
    --name postgresql \
    --hostname postgresql94 \
    --rm \
    --publish 5432:5432 \
    --volume /srv/docker/postgresql:/var/lib/postgresql \
    --env 'DB_USER=dbuser' --env 'DB_PASS=dbuserpass' \
    sameersbn/postgresql:9.4-21 &

until nc -w 0 $(docker-machine ip default) 5432 || [ $SECONDS -gt 10 ]; do sleep 1; done
docker exec -i postgresql sudo -u postgres psql -a < $1

