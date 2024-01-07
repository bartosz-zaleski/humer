#!/bin/bash

source bash/common.sh

# 0. Sanity check

## 0.1 Docker
docker &>/dev/null
if [[ ! $? == 0 ]]; then _stderr "ERROR" "install.sh ERROR: 'docker' command failed"; exit 1; fi

# 0.3 is root?
if [[ ! $USER == "root" ]]; then _stderr "ERROR" "install.sh ERROR: must be root to run 'build.sh'"; exit 1; fi

# 0.4 sqlite
which sqlite3 &>/dev/null
if [[ ! $? == 0 ]]; then _stderr "ERROR" "install.sh ERROR: no sqlite3 installed"; exit 1; fi

# 1. Prerequisites

docker pull ubuntu:latest
docker pull grafana/grafana

# 3. Files

mkdir /root/.humer/
cp bash/read_sensor.sh /root/.humer/
mkdir /root/.humer/grafana/
cp -ar bash/humer.sh /usr/bin/humer
cp -ar config/devices /root/.humer/devices

# 2. Build dockerfile/sensor

(
    cd dockerfiles/sensor
    docker build --tag humer/sensor:latest .
)

# 3. Build dockerfile/grafana

(
    cd dockerfiles/grafana
    docker build --tag humer/grafana:latest .
)

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

            sed -i "s|\[location\]|$device_location|g" "humer-sensors-$device_location.service"
            sed -i "s|\[MAC\]|$mac|g" "humer-sensors-$device_location.service"
            sed -i "s|\[interval\]|$interval|g" "humer-sensors-$device_location.service"

            sed -i "s|\[location\]|$device_location|g" "humer-sensors-$device_location.timer"
            sed -i "s|\[MAC\]|$mac|g" "humer-sensors-$device_location.timer"
            sed -i "s|\[interval\]|\*:0/$interval|g" "humer-sensors-$device_location.timer"
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
        systemctl enable "humer-sensors-$device_location.service"
        systemctl start "humer-sensors-$device_location.service"
        systemctl enable "humer-sensors-$device_location.timer"
        systemctl start "humer-sensors-$device_location.timer"

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
        temperature REAL, \
        humidity REAL, \
        battery INTEGER, \
        FOREIGN KEY(id_sensor) REFERENCES sensors(id_sensor) \
    ); \
"

sqlite3 /root/.humer/humer.db " \
    CREATE TABLE IF NOT EXISTS humer_logs ( \
        id_error INTEGER PRIMARY KEY ASC, \
        id_sensor INTEGER, \
        severity INTEGER, \
        tstamp INTEGER, \
        log TEXT, \
        FOREIGN KEY(id_sensor) REFERENCES sensors(id_sensor)
    ); \
"

# TODO - verify the installation. Perhaps before starting the services?