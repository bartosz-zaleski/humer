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

    # Start daemon
    _stderr "INFO" "Starting Device(${mac})"
    "${SCRIPT_DIR}"/../shell/listener.sh "${mac}" &
    
done<"${WORKSPACE}/${PIPEDEVIN}"