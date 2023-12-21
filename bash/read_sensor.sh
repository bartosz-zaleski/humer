#!/bin/bash

mac=$1

# TODO - validate MAC

echo "$mac" >> readings
/usr/bin/docker run -ti sensors:latest "$mac" >> readings
 