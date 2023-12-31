#!/bin/bash

source bash/common.sh

# 0. Sanity check

## 0.1 Docker
docker &>/dev/null
if [[ ! $? == 0 ]]; then _stderr "ERROR" "install.sh ERROR: 'docker' command failed"; exit 1; fi

## 0.2 bash replace
which replace &>/dev/null
if [[ ! $? == 0 ]]; then _stderr "ERROR" "install.sh ERROR: 'replace' command failed"; exit 1; fi

# 0.3 is root?
if [[ ! $USER == "root" ]]; then _stderr "ERROR" "install.sh ERROR: must be root to run 'build.sh'"; exit 1; fi

# 0.4 sqlite
which sqlite3 &>/dev/null
if [[ ! $? == 0 ]]; then _stderr "ERROR" "install.sh ERROR: no sqlite3 installed"; exit 1; fi

# 1. Prerequisites

docker pull ubuntu:latest

# 3. Files

mkdir /root/.humer/
cp bash/read_sensor.sh /root/.humer/

# 2. Build dockerfile/sensor

(
    cd dockerfiles/sensor
    docker build --tag sensor:latest .
)

# 3. Build dockerfile/mariadb

# 4. Prepare services

workspace=$(mktemp -d)

while read -r line; do

    # Trim
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
            replace '[interval]' "*:0/$interval" -- "humer-sensors-$device_location.timer"
        )
    fi

done < config/devices

# 5. Deploy services

while read -r line; do

    # Trim
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

# 6. Create database

# TODO - not null

sqlite3 /root/.humer/humer.db "VACUUM;"

sqlite3 /root/.humer/humer.db " \
    CREATE TABLE IF NOT EXISTS sensors ( \
        id_sensor INTEGER PRIMARY KEY ASC, \
        location TEXT, \
        mac TEXT, \
        UNIQUE(mac) \
    ); \
"

while read -r line; do

    line=$(echo "$line" | xargs)
    
    device_type=$(echo "$line" | cut --delimiter " " --fields 1)
    device_location=$(echo "$line" | cut --delimiter " " --fields 2)
    mac=$(echo "$line" | cut --delimiter " " --fields 3)

    if [[ $device_type == "sensor" ]]; then

        sqlite3 /root/.humer/humer.db " \
            INSERT INTO sensors(location, mac) \
            VALUES('$device_location', '$mac');
        "
    fi
done < config/devices

sqlite3 /root/.humer/humer.db " \
    CREATE TABLE IF NOT EXISTS sensor_readings ( \
        id_reading INTEGER PRIMARY KEY ASC, \
        id_sensor INTEGER, \
        tstamp INTEGER, \
        temperature INTEGER, \
        humidity INTEGER, \
        battery INTEGER, \
        FOREIGN KEY(id_sensor) REFERENCES sensors(id_sensor) \
    ); \
"

sqlite3 /root/.humer/humer.db " \
    CREATE TABLE IF NOT EXISTS sensor_errors ( \
        id_error INTEGER PRIMARY KEY ASC, \
        id_sensor INTEGER, \
        tstamp INTEGER, \
        error_message TEXT, \
        FOREIGN KEY(id_sensor) REFERENCES sensors(id_sensor)
    ); \
"

