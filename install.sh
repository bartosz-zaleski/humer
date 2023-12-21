#!/bin/bash

source bash/common.sh

# 0. Sanity check

docker &>/dev/null
if [[ ! $? == 0 ]]; then _stderr "ERROR" "build.sh ERROR: 'docker' command failed"; exit 1; fi

which replace &>/dev/null
if [[ ! $? == 0 ]]; then _stderr "ERROR" "build.sh ERROR: 'replace' command failed"; exit 1; fi

if [[ ! $USER == "root" ]]; then _stderr "ERROR" "build.sh ERROR: must be root to run 'build.sh'"; exit 1; fi


# 1. Prerequisites

docker pull ubuntu:latest
docker pull mariadb:latest

# 2. Build dockerfile/sensor

(
    cd dockerfiles/sensor
    docker build --tag sensor:latest .
)

# 3. Build dockerfile/mariadb

# 4. Prepare services

workspace=$(mktemp -d)

while read -r line; do

    line=$(echo "$line" | xargs)

    device_type=$(echo "$line" | cut --delimiter " " --fields 1)
    device_location=$(echo "$line" | cut --delimiter " " --fields 2)
    mac=$(echo "$line" | cut --delimiter " " --fields 3)
    interval=$(echo "$line" | cut --delimiter " " --fields 4)

    if [[ $device_type == "sensor" ]]; then
        cp -ar "service/humer-sensors-[location].service" "$workspace/humer-sensors-$device_location.service"
        cp -ar "service/humer-sensors-[location].timer" "$workspace/humer-sensors-$device_location.timer"

        (
            cd $workspace

            replace '[location]' "$device_location" -- "humer-sensors-$device_location.service"
            replace '[MAC]' "$mac" -- "humer-sensors-$device_location.service"
            replace '[interval]' "$interval" -- "humer-sensors-$device_location.service"

            replace '[location]' "$device_location" -- "humer-sensors-$device_location.timer"
            replace '[MAC]' "$mac" -- "humer-sensors-$device_location.timer"
            replace '[interval]' "$interval" -- "humer-sensors-$device_location.timer"
        )
    fi

done < config/devices

# 5. Deploy services

cd $workspace

chown root:root *.service
chown root:root *.timer

chmod 644 *.service
chmod 644 *.timer

mv *.service /etc/systemd/system/
mv *.timer /etc/systemd/system/

# 6. Restart systemd

systemctl daemon-reload
systemctl enable humer-sensors-*
systemctl start humer-sensors-*.timer

