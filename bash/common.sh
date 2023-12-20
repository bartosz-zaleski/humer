#!/bin/bash

#
# Description:
#   This function outputs nice, coloured log into the STDERR
#
# Must have ENV: 
#   none
#
# Input:
#   1: Message type, required: ( INFO, ERROR, OK, IMP(roving), DET(eriorating), NEUTRAL, WARNING )
#   2: The message: string
#
# Output:
#   STDERR: formatted message
#   STDOUT: 0 if OK, 1 if error
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
