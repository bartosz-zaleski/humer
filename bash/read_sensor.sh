#!/bin/bash

mac=$1
device_location=$2

# TODO - validate MAC
# TODO - validate location

reading=$(/usr/bin/docker run --rm --net host sensor:latest "$mac")

if [[ "$reading" =~ ^OK.*$ ]]; then
    echo "$reading" >> /root/.humer/readings





elif [[ "$reading" =~ ^ERROR.*$ ]]; then
    echo "$reading" >> /root/.humer/errors
    # exit 1 - for systemd to know that the service has failed
fi
