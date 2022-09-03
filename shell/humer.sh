#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Source common and config
source "${SCRIPT_DIR}/../shell/common.sh"
source "${SCRIPT_DIR}/../config/config"

# Trap
#trap cleanup EXIT

function cleanup() {
    return 0
}

devices=()

_stderr "INFO" "Starting humer. Time interval: ${INTERVAL}"

while read -r line; do

    _stderr "INFO" "Device: ${line}"
    devices+=( "${line}" )

done < "${SCRIPT_DIR}/../config/devices"


# Main loop

while true; do
    for line in "${devices[@]}"; do

        mac=$(echo "${line}" | cut --delimiter " " --field 1)
        location=$(echo "${line}" | cut --delimiter " " --field 2)

        reading=$(docker run -ti --net host jenkins/lywsd03mmc "${mac}")
        _stderr "INFO" "${location}(${mac}): ${reading}"

        temperature=$(echo "${reading}" | grep --perl-regexp --only-matching '^Temperature: [0-9\.]{5}')
        temperature=$(echo "${temperature}" | cut --delimiter " " --fields 2)

        humidity=$(echo "${reading}" | grep --perl-regexp --only-matching '^Humidity: [0-9]{2}')
        humidity=$(echo "${humidity}" | cut --delimiter " " --fields 2)

        battery=$(echo "${reading}" | grep --perl-regexp --only-matching '^Battery: [0-9]{1,3}')
        battery=$(echo "${battery}" | cut --delimiter " " --fields 2)

        if [[ \
            $temperature =~ ^[0-9]{2}\.[0-9]{2}$ && \
            $humidity =~ ^[0-9]{2}$ && \
            $battery =~ ^[0-9]{1,3}$ \
        ]]; then
            
            cat <<EEE > "${WORKSPACE}/${location}"
# HELP humidity Humidity
# TYPE humidity gauge
humidity ${humidity}
# HELP temperature Temperature
# TYPE humidity gauge
temperature ${temperature}
# HELP battery Battery
# TYPE humidity gauge
battery ${battery}
EEE
            
        else 
            _stderr "WARNING" "Reading incorrect, skipping" 
            _stderr "WARNING" "[${reading}]" 
        fi

        unset out mac location reading temperature humidity battery  

        sleep 3s
    done

    sleep "${SENSOR_READING_INTERVAL}"

done