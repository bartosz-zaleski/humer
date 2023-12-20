#!/bin/bash

###
# 

function _stderr() {

    RED='\033[0;31m'
    GREEN='\033[0;32m'
    ORANGE='\033[0;33m'
    BLUE='\033[0;34'
    PURPLE='\033[0;35m'
    NC='\033[0m'

    local message_type="${1}"
    shift
    local message="${1}"

    local out

    if [[ $message_type == 'INFO' ]]; then
        out="${BLUE}INFO: $message${NC}"
    elif [[ $message_type == 'ERROR' ]]; then 
        out="${RED}ERROR: $message${NC}"
    elif [[ $message_type == 'OK' ]]; then
        out="${GREEN}OK: $message${NC}"
    elif [[ $message_type == 'IMP' ]]; then
        out="${PURPLE}IMPROVING: $message${NC}"
    elif [[ $message_type == 'DET' ]]; then
        out="${GREEN}DETERIORATING: $message${NC}"
    elif [[ $message_type == 'NEUTRAL' ]]; then
        out="${NC}  $message"
    elif [[ $message_type == 'WARNING' ]]; then
        out="${PURPLE}WARNING: $message${NC}"
    else
        echo "${RED} INCORRECT MESSAGE TYPE [${message_type}] ${NC}" 1>&2
        return 1
    fi

    echo "${out}" 1>&2
}

function object_path_to_mac() {
    local path="${1}"

    local mac

    if [[ ! $path =~ ^object\ path\ \"/org/bluez/hci0/dev_[A-F0-9]{2}_[A-F0-9]{2}_[A-F0-9]{2}_[A-F0-9]{2}_[A-F0-9]{2}_[A-F0-9]{2}\"$ ]]; then
        _stderr "ERROR" "INCORRECT OBJECT PATH SUPPLIED [${path}]"
        return 1
    else
        mac=$(echo "${path:33:17}" | sed 's/_/:/g')

        if [[ ! $mac =~ ^[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}:[A-F0-9]{2}$ ]]; then 
            _stderr "ERROR" "INCORRECT MAC ADDRESS"
            return 1
        else 
            echo "${mac}"
        fi
    fi
}