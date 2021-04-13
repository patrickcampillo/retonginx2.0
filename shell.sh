#!/usr/bin/env bash

# run.sh

# run the container in the background
# /data is persisted using a named container

docker run \
    --rm \
    -it \
    -p 8080:80 \
    -p 8081:443 \
    --name="test_nginx" \
    test_nginx \
    /bin/bash
