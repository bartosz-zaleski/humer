#!/bin/bash

mac=$1

# TODO - validate MAC

reading=$(/usr/bin/docker run --rm --net host humer/sensor:latest "$mac")

if [[ "$reading" =~ ^OK.*$ ]]; then

    # e.g. 
    # OK,1704055701,A4:C1:38:A5:B2:D0,70,18.04,82

    tstamp=$(echo "$reading" | cut --delimiter ',' --fields 2)
    mac=$(echo "$reading" | cut --delimiter ',' --fields 3)
    temperature=$(echo "$reading" | cut --delimiter ',' --fields 4)
    humidity=$(echo "$reading" | cut --delimiter ',' --fields 5)
    battery=$(echo "$reading" | cut --delimiter ',' --fields 6)

    sqlite3 /root/.humer/humer.db " \
        INSERT INTO sensor_readings(id_sensor, tstamp, temperature, humidity, battery) \
        SELECT \
            id_sensor, \
            '$(date +%s)' AS tstamp, \
            '$temperature' AS temperature, \
            '$humidity' AS humidity, \
            '$battery' AS battery \
        FROM sensors WHERE mac='$mac' \
    "

elif [[ "$reading" =~ ^ERROR.*$ ]]; then

    
    # e.g. 
    # ERROR,1704121409,A4:C1:38:64:27:47,Failed to connect to peripheral A4:C1:38:64:27:47 addr type: public

    mac=$(echo "$reading" | cut --delimiter ',' --fields 3)
    error_message=$(echo "$reading" | cut --delimiter ',' --fields 4)

    sqlite3 /root/.humer/humer.db " \
        INSERT INTO sensor_errors(id_sensor, tstamp, severity, error_message) \
        SELECT \
            id_sensor, \
            '$(date +%s)' AS tstamp, \
            50, \
            '$error_message' AS error_message \
        FROM sensors WHERE mac='$mac' \
    "
fi
