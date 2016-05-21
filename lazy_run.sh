#!/bin/bash

# ref: https://github.com/sameersbn/docker-postgresql

docker run --name postgresql -itd --restart always \
  --publish 5432:5432 \
  --volume /srv/docker/postgresql:/var/lib/postgresql \
  sameersbn/postgresql:9.4-21

docker exec -i postgresql sudo -u postgres psql -a < lazy.sql

