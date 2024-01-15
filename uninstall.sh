#!/bin/bash

show_help() {

echo '
Usage: ./humer.sh [flags] [action]
Manually run various functions of Humer.

Flags:
--help                    Display help
--version                 Display version
--remove_db               Remove the database file
--remove_images           Remove docker images

Examples

./humer.sh --device_type "sensor" --device_location "kitchen" read      Get reading from the device "sensor", located in "kitchen"
./humer.sh --device_type "sensor" --device_location "bathroom" mac      Get the MAC address of the device "sensor", located in "bathroom"
./humer.sh --device_mac "AA:BB:CC:DD:EE:FF" read                        Get reading from the device "AA:BB:CC:DD:EE:FF"
'
}

# 0. Sanity check


if ! docker &>/dev/null; then _stderr "ERROR" "build.sh ERROR: 'docker' command failed"; exit 1; fi

if [[ ! $EUID == 0 ]]; then _stderr "ERROR" "build.sh ERROR: must be root to run 'build.sh'"; exit 1; fi

# 1. Parameters

export remove_db=0
export remove_images=0

export CURRENT_VERSION="0.0.1"

while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_help
            exit 0
            ;;
        --version)
            echo "$CURRENT_VERSION"
            exit 0
            ;;
        --remove_db)
            export remove_db=1
            shift
            ;;
        --remove_images)
            export remove_images=1
            shift
            ;;
         *)
            echo -e "\e[31mERROR: Incorrect parameter: $1\e[0m"
            echo ""
            show_help
            exit 1
            ;;
    esac
done   

# 1. Remove services

while read -r line; do

    line=$(echo "$line" | xargs)

    device_type=$(echo "$line" | cut --delimiter " " --fields 1)
    device_location=$(echo "$line" | cut --delimiter " " --fields 2)

    if [[ $device_type == "sensor" ]]; then

        systemctl stop "humer-sensors-$device_location.timer"
        systemctl disable "humer-sensors-$device_location.timer"
        
        systemctl stop "humer-sensors-$device_location.service"
        systemctl disable "humer-sensors-$device_location.service"

        rm -f "/etc/systemd/system/humer-sensors-$device_location.service"
        rm -f "/etc/systemd/system/humer-sensors-$device_location.timer"

    fi

done < config/devices

systemctl daemon-reload
systemctl reset-failed

# 2. Remove files

rm -f /root/.humer/read_sensor.sh
rm -f /usr/bin/humer

if [[ $remove_db == "1" ]]; then
    rm -f /root/.humer/humer.db
    rm -rf /root/.humer/
fi

# 4. Remove docker images

if [[ $remove_images == "1" ]]; then
    docker rmi humer/sensor:latest --force

    # (
    #     cd grafana/ || exit 1
    #     docker compose down
    # )

    # docker rmi humer/grafana --force
fi