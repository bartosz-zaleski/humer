#!/bin/bash

mac=$1
device_location=$2

# TODO - validate MAC
# TODO - validate location

reading=$(/usr/bin/docker run --rm --net host sensor:latest "$mac")

if [[ "$reading" =~ ^OK.*$ ]]; then
    echo "$reading" >> /root/.humer/readings

    tstamp=$(echo "$reading" | cut --delimiter ',' --fields 2)
    mac=$(echo "$reading" | cut --delimiter ',' --fields 3)
    temperature=$(echo "$reading" | cut --delimiter ',' --fields 4)
    humidity=$(echo "$reading" | cut --delimiter ',' --fields 5)
    battery=$(echo "$reading" | cut --delimiter ',' --fields 6)

    sqlite3 /root/.humer/humer.db " \
        INSERT INTO sensor_readings(id_sensor, tstamp, temperature, humidity, battery)
        SELECT \
            id_sensor,
            '$(date +%s)' AS timestamp,
            '$temperature' AS temperature,
            '$humidity' AS humidity,
            '$battery' AS battery
        FROM sensors WHERE mac='$mac'
    "

elif [[ "$reading" =~ ^ERROR.*$ ]]; then
    echo "$reading" >> /root/.humer/errors
    # exit 1 - for systemd to know that the service has failed
fi



#OK,1704055701,A4:C1:38:A5:B2:D0,70,18.04,82
#ERROR,Failed to connect to peripheral A4:C1:38:A5:B2:D0, addr type: public
