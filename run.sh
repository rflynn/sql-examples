#!/bin/bash

# ref: https://github.com/sameersbn/docker-postgresql

set -o xtrace
set -o errexit
set -o pipefail

which docker-machine && eval $(docker-machine env)

cleanup()
{
    docker stop postgresql
}
trap cleanup EXIT

docker stop postgresql || true

docker run \
    --name postgresql \
    --hostname postgresql94 \
    --rm \
    --publish 5432:5432 \
    --volume /srv/docker/postgresql:/var/lib/postgresql \
    --env 'DB_USER=dbuser' --env 'DB_PASS=dbuserpass' \
    sameersbn/postgresql:9.4-21 &

while [ $SECONDS -lt 10 ] && ! docker exec -i postgresql sudo -u postgres psql < <(echo select 1) &> /dev/null
do
    sleep 1
done

if [ $# -gt 0 ]
then
    docker exec -i postgresql sudo -u postgres psql -a < $1
else
    docker exec -i postgresql sudo -u postgres psql
fi

docker stop postgresql

