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

if [[ -p "${WORKSPACE}/${PIPEDEVOUT}" ]]; then 
    _stderr "INFO" "Pipeline ${WORKSPACE}/${PIPEDEVOUT} already exists"
else
    mkfifo "${WORKSPACE}/${PIPEDEVOUT}"
fi

# Listen to DBus

dbus-monitor --system "type='signal',sender='org.bluez',interface='org.freedesktop.DBus.ObjectManager',member='InterfacesRemoved'" > "${WORKSPACE}/${PIPEDEVOUT}"