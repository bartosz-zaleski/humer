#!/bin/bash

# TODO - uncomment in production
# docker pull bats/bats:latest

docker run \
    -ti \
    --volume "$PWD:/code/humer/" \
    bats/bats:latest \
    humer/test.bats