#!/bin/bash

# 0. Sanity check


# 1. Prerequisites

docker pull ubuntu:latest
docker pull mariadb:latest

# 2. Build dockerfile/sensor

(
    cd dockerfiles/sensor
    docker build --tag sensor:latest .
)

# 3. Build dockerfile/mariadb