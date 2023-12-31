#!/bin/bash

source bash/common.sh

# TODO flags for removing docker images as well

# 0. Sanity check

docker &>/dev/null
if [[ ! $? == 0 ]]; then _stderr "ERROR" "build.sh ERROR: 'docker' command failed"; exit 1; fi

which replace &>/dev/null
if [[ ! $? == 0 ]]; then _stderr "ERROR" "build.sh ERROR: 'replace' command failed"; exit 1; fi

if [[ ! $USER == "root" ]]; then _stderr "ERROR" "build.sh ERROR: must be root to run 'build.sh'"; exit 1; fi

# 1. Remove services

while read -r line; do

    line=$(echo "$line" | xargs)

    device_type=$(echo "$line" | cut --delimiter " " --fields 1)
    device_location=$(echo "$line" | cut --delimiter " " --fields 2)
    mac=$(echo "$line" | cut --delimiter " " --fields 3)
    interval=$(echo "$line" | cut --delimiter " " --fields 4)

    if [[ $device_type == "sensor" ]]; then

        systemctl stop humer-sensors-$device_location.timer
        systemctl disable humer-sensors-$device_location.timer
        
        systemctl stop humer-sensors-$device_location.service
        systemctl disable humer-sensors-$device_location.service

        rm -f "/etc/systemd/system/humer-sensors-$device_location.service"
        rm -f "/etc/systemd/system/humer-sensors-$device_location.timer"

    fi

done < config/devices

systemctl daemon-reload
systemctl reset-failed

# 2. Remove files

rm -rf /root/.humer/