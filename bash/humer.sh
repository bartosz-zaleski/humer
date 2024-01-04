#!/bin/bash

show_help() {

echo '
Usage: ./humer.sh [flags] [action]
Manually run various functions of Humer.

Flags:
--help              Display help
--version           Display version
--device_type       Type of the device to be addressed
--device_location   Location of the device to be addressed
--device_mac        MAC address of the device to be addressed

Actions:
read                Get current reading from a device
mac                 Get MAC address of a device

Examples

./humer.sh --device_type "sensor" --device_location "kitchen" read      Get reading from the device "sensor", located in "kitchen"
./humer.sh --device_type "sensor" --device_location "bathroom" mac      Get the MAC address of the device "sensor", located in "bathroom"
./humer.sh --device_mac "AA:BB:CC:DD:EE:FF" read                        Get reading from the device "AA:BB:CC:DD:EE:FF"
' >&2
}

readonly CURRENT_VERSION="0.1"

export version=""
export verbose=""
export device_type=""
export device_location=""
export device_mac=""

for param in "$@"; do
    case $param in
        --help)
            show_help
            exit 0
            ;;
        --version)
            echo "$CURRENT_VERSION"
            exit 0
            ;;
        

        *)
            echo -e "\e[31mIncorrect parameter: $param\e[0m"
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
# echo ">> action: $@ <<"