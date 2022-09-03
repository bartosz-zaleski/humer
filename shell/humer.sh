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
    for device in "${devices[@]}"; do

        reading=$(docker run -ti --net host jenkins/lywsd03mmc "${device}")
        _stderr "INFO" "${device}: ${reading}"

        temperature=$(echo "${reading}" | grep --perl-regexp --only-matching '^Temperature: [0-9\.]{5}')
        temperature=$(echo "${temperature}" | cut --delimiter " " --fields 2)

        humidity=$(echo "${reading}" | grep --perl-regexp --only-matching '^Humidity: [0-9]{2}')
        humidity=$(echo "${humidity}" | cut --delimiter " " --fields 2)

        battery=$(echo "${reading}" | grep --perl-regexp --only-matching '^Battery: [0-9]{2}')
        battery=$(echo "${battery}" | cut --delimiter " " --fields 2)

        # TODO
        # need to know whether 1st field is MAC or name (e.g. "Kitchen") and 2nd field is timestamp or sth human-friendly

        if [[ \
            $temperature =~ ^[0-9]{2}\.[0-9]{2}$ && \
            $humidity =~ ^[0-9]{2}$ && \
            $battery =~ ^[0-9]{2}$ \
        ]]; then
            
            cat <<EEE > "${WORKSPACE}/bathroom"
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
            
            unset out
        else 
            _stderr "WARNING" "Reading incorrect, skipping" 
            _stderr "WARNING" "[${temperature}] [${humidity}] [${battery}]" 
        fi       

        sleep 3s
    done

    sleep "${SENSOR_READING_INTERVAL}"

done