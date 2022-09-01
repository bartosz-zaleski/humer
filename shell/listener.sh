#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Source common and config
source "${SCRIPT_DIR}/../shell/common.sh"
source "${SCRIPT_DIR}/../config/config"

# Trap
trap cleanup EXIT

function cleanup() {
    _stderr "INFO" "listener.sh stopping; removing Device(${mac})"

    (
        _stderr "INFO" "Locking for removal of Device(${mac})..." 
        flock --wait 60 200
        _stderr "INFO" "Locked"
        
        # Update DB
        
        grep -v "${mac}" --no-filename .* "${WORKSPACE}"/.devices > "${WORKSPACE}"/.devices
        _stderr "INFO" ".devices updated"

        # Unlock

        _stderr "INFO" "Unlocking"
    ) 200>"${WORKSPACE}"/.lock
    _stderr "INFO" "Device(${mac}) removed; unlocked"
}

# Main

mac="${1}"
mac=$(echo "${mac}" | xargs)

error_count=0
index=0

if [[ ! $mac =~ ^[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}$ ]]; then
    _stderr "ERROR" "listener.sh: incorrect MAC address: ${mac}"
    # Disable TRAP
    trap - EXIT
    exit 1
fi

(
    _stderr "INFO" "Locking for new Device(${mac})"
    flock --wait 60 200
    _stderr "INFO" "Locked for new Device(${mac})"
    
    # Update DB
    
    echo "${mac}" >> "${WORKSPACE}"/.devices
    _stderr "INFO" ".devices updated"

    # Start daemon
    "${SCRIPT_DIR}"/../shell/listener.sh "${mac}" &
    _stderr "INFO" "Listener daemon started"

    # Unlock

    _stderr "INFO" "Unlocking"    
) 200>"${WORKSPACE}"/.lock
_stderr "INFO" "New Device(${mac}) added; unlocked"

while read -r line; do
    if [[ $line =~ ^Notification\ handle\ =\ 0x0036\ value:\ [0-9a-f]{2}\ [0-9a-f]{2}\ [0-9a-f]{2}\ [0-9a-f]{2}\ [0-9a-f]{2}$ ]]; then

        index=$(( index+1 ))

        temp="${line:39:2}${line:36:2}"
        hum="${line:42:2}"
        batt="${line:48:2}${line:45:2}"

        temp=$(echo "ibase=16; ${temp^^}" | bc)
        hum=$(echo "ibase=16; ${hum^^}" | bc)

        batt=$(echo "ibase=16; ${batt^^}" | bc)
        batt=$(echo "scale=3; ${batt} / 1000" | bc)

        if [[ $temp =~ ^[0-9]{4}$ && $hum =~ ^[0-9]{2}$ && $batt =~ ^[0-9]{1,2}.[0-9]{1,3}$ ]]; then
            
            # Get readings
            _stderr "INFO" "temp=${temp:0:4} hum=${hum} batt=${batt} error=${error_count}"
            echo "${mac},${temp:0:4},${hum},${batt}" >> "${WORKSPACE}"/.readings

            # Decrease error count every 10 successful readings; not below 0
            if (( index%10==0 && error_count>0 )); then
                error_count=$(( error_count-1 ))
                _stderr "IMP" "${mac} error_count=${error_count}"
            fi

        else
            error_count=$(( error_count+1 ))
            _stderr "DET" "${mac} error_count=${error_count}"
        fi
        
    else 
        _stderr "ERROR" "unexpected input: ${line}" 1>&2
        error_count=$(( error_count+1 ))
        _stderr "DET" "${mac} error_count=${error_count}"
    fi

    if (( error_count > 100 )); then
        _stderr "ERROR" "error count threshold reached" 1>&2
    fi


done < <(gatttool -b "${mac}" --char-write-req --handle=0x0038 --value=0100 --listen)
