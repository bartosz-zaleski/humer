#!/bin/bash

mac=$1

# TODO - validate MAC

whoami

echo "$mac" >> readings
/usr/bin/docker run -ti sensors:latest "$mac" >> /home/humer/.humer/readings
