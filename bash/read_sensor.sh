#!/bin/bash

mac=$1

# TODO - validate MAC


o=$(/usr/bin/docker run --net host sensor:latest "$mac" >> /root/.humer/readings)

# Sanitise output


echo "$(date +%s) $mac" >> /root/.humer/readings