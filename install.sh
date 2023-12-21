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

# 3. User "humer"

useradd \
    --home-dir /home/humer/ \
    --create-home \
    --shell /usr/sbin/nologin \
    humer

sudo --user humer mkdir /home/humer/.humer
sudo --user humer touch /home/humer/.humer/readings
chmod +x /home/humer/.humer/readings
cp bash/read_sensor.sh /home/humer/.humer/
chown -R humer:humer /home/humer/.humer

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

while read -r line; do

    line=$(echo "$line" | xargs)

    device_type=$(echo "$line" | cut --delimiter " " --fields 1)
    device_location=$(echo "$line" | cut --delimiter " " --fields 2)

    if [[ $device_type == "sensor" ]]; then
        
        chown root:root "$workspace/humer-sensors-$device_location.service"
        chown root:root "$workspace/humer-sensors-$device_location.timer"

        chmod 644 "$workspace/humer-sensors-$device_location.service"
        chmod 644 "$workspace/humer-sensors-$device_location.timer"
        
        mv "$workspace/humer-sensors-$device_location.service" "/etc/systemd/system/humer-sensors-$device_location.service"
        mv "$workspace/humer-sensors-$device_location.timer" "/etc/systemd/system/humer-sensors-$device_location.timer"

        systemctl daemon-reload
        systemctl start "humer-sensors-$device_location.service"
        systemctl enable "humer-sensors-$device_location.timer"

    fi
done < config/devices