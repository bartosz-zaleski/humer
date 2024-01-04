#!/bin/bash

show_help() {

echo '
Usage: ./humer.sh [flags] [action]
Manually run various functions of Humer.

Flags:
--help              Display help
--version           Display version
--device_file       Path to the "devices" config file. Default: /root/.humer/devices
--device_type       Type of the device to be addressed
--device_location   Location of the device to be addressed
--device_mac        MAC address of the device to be addressed

Actions:
read                Get current reading from a device
mac                 Get MAC address of a device
add_device
enable_device
disable_device
remove_device

Examples

./humer.sh --device_type "sensor" --device_location "kitchen" read      Get reading from the device "sensor", located in "kitchen"
./humer.sh --device_type "sensor" --device_location "bathroom" mac      Get the MAC address of the device "sensor", located in "bathroom"
./humer.sh --device_mac "AA:BB:CC:DD:EE:FF" read                        Get reading from the device "AA:BB:CC:DD:EE:FF"
' >&2
}

readonly CURRENT_VERSION="0.0.1"

export version=""
export verbose=""
export device_type=""
export device_location=""
export device_mac=""
export devices_file=/root/.humer/devices
export action=""

if [[ "${#@}" == 0 ]]; then 
    echo -e "\e[31mERROR: No parameters supplied\e[0m"
    echo ""
    show_help
    exit 1
fi

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
        --devices_file)
            export devices_file=$2
            shift
            shift
            ;;
        --device_type)
            export device_type=$2
            shift
            shift
            ;;
        get_mac)
            export action=get_mac
            shift
            ;;
        validate_devices_file)
            export action=validate_devices_file
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

# echo ">> version: $version <<"
# echo ">> verbose: $verbose <<"
# echo ">> device_type: $device_type <<"
# echo ">> device_location: $device_location <<"
# echo ">> device_mac: $device_mac <<"

### Functions - input validation

validate_device_type() {
    device_type=$1

    if [[ $device_type =~ ^sensor|smartplug$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_device_location() {
    device_location=$1

    if [[ $device_location =~ ^bedroom|bathroom|kitchen|livingroom$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_mac() {
    mac=$1

    if [[ $mac =~ ^[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_time_interval() {
    interval=$1

    if [[ $interval =~ ^[0-9]{1}$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_devices_file() {

    _devices_file=$1

    if [[ -n $_devices_file ]]; then
        # File exists?
        if [[ ! -f $_devices_file ]]; then
            return 1
        else
            # Syntax correct?
            while read -r line; do

                line=$(echo "$line" | xargs)

                if [[ -z $line ]]; then continue; fi

                _device_type=$(echo $line | cut --delimiter " " --fields 1)
                _device_location=$(echo $line | cut --delimiter " " --fields 2)
                _mac=$(echo $line | cut --delimiter " " --fields 3)
                _interval=$(echo $line | cut --delimiter " " --fields 4)
                
                validate_device_type     "$_device_type"       || return 2
                validate_device_location "$_device_location"   || return 2
                validate_mac             "$_mac"               || return 2
                validate_time_interval   "$_interval"          || return 2

            done < $_devices_file

            return 0
        fi
    else
        return 3
    fi
}

### Functions - actual

get_mac() {
    devices_file=$1
    device_type=$2
    device_location=$3


}


# Run the script

case $action in
    get_mac)
        get_mac $devices_file $device_type $device_location
        ;;
    validate_devices_file)
        if validate_devices_file $devices_file == 0; then echo -e "\e[32mCorrect\e[0m"; else echo -e "\e[31mIncorrect\e[0m"; fi
        ;;
    *)
        echo -e "\e[31mERROR: Incorrect action: $action\e[0m"
        exit 1
        ;;
esac





