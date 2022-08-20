#!/bin/bash

mac="${1}"
mac=$(echo "${mac}" | xargs)

error_count=0
index=0

if [[ ! $mac =~ ^[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}$ ]]; then
    echo "ERROR: incorrect MAC address: ${mac}"
    exit 1
fi

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
            
            # TODO - serialise
            echo "temp=${temp:0:4} hum=${hum} batt=${batt} error=${error_count}"

            # Decrease error count every 10 successful readings; not below 0
            if (( index%10==0 && error_count>0 )); then
                error_count=$(( error_count-1 ))
            fi

        else
            error_count=$(( error_count+1 ))
        fi
        
    else 
        echo "ERROR: unexpected input: ${line}" 1>&2
        error_count=$(( error_count+1 ))
    fi

    if (( error_count > 100 )); then 
        echo "ERROR: error count threshold reached" 1>&2
    fi


done < <(gatttool -b "${mac}" --char-write-req --handle=0x0038 --value=0100 --listen)
