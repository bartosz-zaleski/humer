#!/bin/bash

# 0. Sanity check

docker &>/dev/null
if [[ ! $? == 0 ]]; then exit 1; fi

# 1. Prerequisites

docker pull ubuntu:latest
docker pull mariadb:latest

# 2. Build dockerfile/sensor

(
    cd dockerfiles/sensor
    docker build --tag sensor:latest .
)

# 3. Build dockerfile/mariadb





###

while read -r line; do 
    
    # Trim
    line=$(echo "$line" | xargs)
    
    
    if [[ -n $line ]]; then
        l=$(echo "$line" | cut --delimiter " " --fields 2)
        echo "$l"
    fi

done < devices
