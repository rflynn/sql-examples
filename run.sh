#!/bin/bash

# ref: https://github.com/sameersbn/docker-postgresql

#set -v

# ensure postgresql container running
docker run \
  --name postgresql \
  --rm \
  --publish 5432:5432 \
  --volume /srv/docker/postgresql:/var/lib/postgresql \
  sameersbn/postgresql:9.4-21 &> /dev/null &

# wait for server or timeout...
timeout=$(($(date +%s) + 10))
while [ $(date +%s) -lt $timeout ] && ! docker exec -i postgresql sudo -u postgres psql < <(echo select 1) &> /dev/null
do
    sleep 1
done

docker exec -i postgresql sudo -u postgres psql -a < /dev/stdin

docker stop postgresql

