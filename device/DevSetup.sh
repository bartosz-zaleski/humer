#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Source common

source "${SCRIPT_DIR}/../shell/common.sh"

# Source config

source "${SCRIPT_DIR}/../config/config"

# Check config validity

if [[ -z "${WORKSPACE}" ]]; then  { _stderr "ERROR" "MISSING VARIABLE: WORKSPACE"; exit 1; } fi
mkdir -p "${WORKSPACE}" || { _stderr "ERROR" "CANNOT CREATE NAMEDPIPE"; exit 1; }
if [[ ! -d "${WORKSPACE}" ]]; then { _stderr "ERROR" "WORKSPACE DOES NOT EXIST"; exit 1; } fi

if [[ -p "${WORKSPACE}/${PIPEDEVIN}" ]]; then 
    _stderr "INFO" "Pipeline ${WORKSPACE}/${PIPEDEVIN} already exists"
else
    mkfifo "${WORKSPACE}/${PIPEDEVIN}"
fi

while read line; do

    mac=
    mac=$(object_path_to_mac "${line}" 2>/dev/null) || continue 

    (
        _stderr "INFO" "Locking for new Device(${mac})" 
        flock --wait 60 200
        _stderr "INFO" "Locked for new Device(${mac})"
        
        # Update DB
        
        echo "${mac}" >> "${WORKSPACE}"/.db
        _stderr "INFO" ".db updated"

        # Start daemon
        "${SCRIPT_DIR}"/../shell/listener.sh "${mac}" &
        _stderr "INFO" "Listener daemon started"

        # Unlock

        _stderr "INFO" "Unlocking"
        sleep 2s
        
    ) 200>"${WORKSPACE}"/.lock
    _stderr "INFO" "New Device(${mac}) added; unlocked"
    

    
    

done<"${WORKSPACE}/${PIPEDEVIN}"