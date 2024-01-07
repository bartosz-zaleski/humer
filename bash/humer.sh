#!/bin/bash

show_help() {

echo '
Usage: ./humer.sh [flags] [action]
Manually run various functions of Humer.

Flags:
--help                  Display help
--version               Display version
--device_file           Path to the "devices" config file. Default: /root/.humer/devices
--device_type           Type of the device to be addressed
--device_location       Location of the device to be addressed
--device_mac            MAC address of the device to be addressed

Actions:
read                    Get current reading from a device
mac                     Get MAC address of a device
add_device
enable_device
disable_device
remove_device
validate_devices_file   Validates whether the "devices" file is of correct structure

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
        --device_location)
            export device_location=$2
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
        disable_device)
            export action=disable_device
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

    local _device_type
    _device_type=$1

    if [[ $_device_type =~ ^sensor|smartplug$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_device_location() {
    
    local _device_location
    _device_location=$1

    if [[ $_device_location =~ ^bedroom|bathroom|kitchen|livingroom$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_mac() {

    local _mac
    _mac=$1

    if [[ $_mac =~ ^[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_time_interval() {

    local _interval
    _interval=$1

    if [[ $_interval =~ ^[0-9]{1}$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_devices_file() {

    local _devices_file
    local _device_type
    local _device_location
    local _mac
    local _interval

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

    local _devices_file
    local _device_type
    local _device_location
    local _mac
    local _line
    local _count

    _devices_file=$1
    _device_type=$2
    _device_location=$3

    # Validate input

    if ! validate_devices_file $_devices_file; then
        echo -e "\e[31m ERROR: Devices file incorrect: $_devices_file \e[0m"
        exit 1
    fi

    if ! validate_device_type $_device_type; then
        echo -e "\e[31m ERROR: Device type incorrect: $_device_type \e[0m"
        exit 1
    fi

    if ! validate_device_location $_device_location; then
        echo -e "\e[31m ERROR: Device location incorrect: $_device_location \e[0m"
        exit 1
    fi

    # Get the MAC from the "devices" file

    _line=$(grep "$_device_type" "$_devices_file" | grep "$_device_location")
    _count=$(echo "$_line" | wc -l)

    if (( $_count == 0 )); then
        echo -e "\e[31m ERROR: Device not found \e[0m"
        exit 1
    elif (( $_count > 1 )); then
        echo -e "\e[31m ERROR: More than one devices found \e[0m"
        exit 1
    fi

    _line=$(echo "$_line" | xargs)
    _mac=$(echo "$_line" | cut --delimiter " " --fields 3)

    echo "$_mac"

}

get_device_type() {

    local _mac
}

get_device_location() {

    local _mac

}

# Disable device

disable_device() {
    local _mac
    local _device_type
    local _device_location
    local _devices_file
    local _groups

    _mac=$1
    _device_type=$2
    _device_location=$3
    _devices_file=$4

    # Validate input

    if [[ -n $_mac ]]; then
        if ! validate_mac $_mac; then
            echo -e "\e[31m ERROR: MAC incorrect: $_mac  \e[0m"
            exit 1
        fi
    fi

    if [[ -n $_device_type ]]; then
        if ! validate_device_type $_device_type; then
            echo -e "\e[31m ERROR: Device type incorrect: $_device_type \e[0m"
            exit 1
        fi
    fi

    if [[ -n $_device_location ]]; then
        if ! validate_device_location $_device_location; then
            echo -e "\e[31m ERROR: Device location incorrect: $_device_location \e[0m"
            exit 1
        fi
    fi

    if [[ -n $_devices_file ]]; then
        if ! validate_devices_file $_devices_file; then
            echo -e "\e[31m ERROR: Devices file incorrect: $_devices_file \e[0m"
            exit 1
        fi
    fi

    # Check if necessary info on the device is available

    if [[ -n $_mac ]]; then

        _device_type=$(get_device_type $_mac $_devices_file)
        _device_location=$(get_device_location $_mac $_devices_file)

        if ! validate_device_type $_device_type; then
            echo -e "\e[31m ERROR: Device type incorrect: $_device_type \e[0m"
            exit 1
        fi

        if ! validate_device_location $_device_location; then
            echo -e "\e[31m ERROR: Device location incorrect: $_device_location \e[0m"
            exit 1
        fi

    elif [[ -n $_device_type && -n $_device_location ]]; then

        # Grand, nothing to do
        true

    else

        echo -e "\e[31m ERROR: Incorrect parameters; provide either MAC and "devices" file or device type and device location \e[0m"
        exit 1

    fi
    
    # Modify _device_type to match the timer/service filename

    if [[ $_device_type == "sensor" ]]; then _device_type="sensors"; fi

    # Must be root or in sudoers

    if [[ $EUID == "0" ]]; then
        
        systemctl stop "humer-$_device_type-$_device_location.timer"
        if [[ $? ]]; then echo -e "\e[32m Stopped:\e[0m: humer-$_device_type-$_device_location.timer"; fi

        systemctl disable "humer-$_device_type-$_device_location.timer"
        if [[ $? ]]; then echo -e "\e[32m Disabled\e[0m: humer-$_device_type-$_device_location.timer"; fi
        
        systemctl stop "humer-$_device_type-$_device_location.service"
        if [[ $? ]]; then echo -e "\e[32m Stopped:\e[0m: humer-$_device_type-$_device_location.service"; fi

        systemctl disable "humer-$_device_type-$_device_location.service"
        if [[ $? ]]; then echo -e "\e[32m Disabled\e[0m: humer-$_device_type-$_device_location.timer"; fi

        exit 0

    elif sudo --non-interactive echo "Yay!" &>/dev/null; then

        sudo systemctl stop "humer-$_device_type-$_device_location.timer"
        if [[ $? ]]; then echo -e "\e[32m Stopped:\e[0m: humer-$_device_type-$_device_location.timer"; fi

        sudo systemctl disable "humer-$_device_type-$_device_location.timer"
        if [[ $? ]]; then echo -e "\e[32m Disabled\e[0m: humer-$_device_type-$_device_location.timer"; fi
        
        sudo systemctl stop "humer-$_device_type-$_device_location.service"
        if [[ $? ]]; then echo -e "\e[32m Stopped:\e[0m: humer-$_device_type-$_device_location.service"; fi

        sudo systemctl disable "humer-$_device_type-$_device_location.service"
        if [[ $? ]]; then echo -e "\e[32m Disabled\e[0m: humer-$_device_type-$_device_location.timer"; fi

        exit 0
        
    else
        echo -e "\e[31m ERROR: must be root or sudoer \e[0m"
        exit 1
    fi
}

device_status() {
    true
}

# Run the script

case $action in
    get_mac)
        get_mac $devices_file $device_type $device_location
        ;;
    validate_devices_file)
        if validate_devices_file $devices_file == 0; then 
            echo -e "\e[32m Correct \e[0m"
        else 
            echo -e "\e[31m Incorrect \e[0m"
        fi
        ;;
    disable_device)
        if [[ -n $mac && -n $devices_file ]]; then
            disable_device "$mac" "" "" "$devices_file"
        elif [[ -n $device_type && -n $device_location ]]; then
            disable_device "" "$device_type" "$device_location" ""
        else
            echo -e "\e[31m ERROR: Incorrect parameters for "$action"; provide MAC and devices file or device type and device location \e[0m"
            exit 1
        fi
        ;;
    *)
        echo -e "\e[31m ERROR: Incorrect action: $action \e[0m"
        exit 1
        ;;
esac





