#!/bin/bash

mac=$1

# TODO - validate MAC

/usr/bin/docker run --rm --net host sensor:latest "$mac" >> /root/.humer/readings
