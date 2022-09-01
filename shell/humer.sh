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

        # insert the reading into DB
        _stderr "NEUTRAL" "${device},$(date +%N),${temperature},${humidity},${battery}"        

        sleep 3s
    done

    sleep "${INTERVAL}"
    _stderr "INFO" "Sleeping ${INTERVAL}"

done