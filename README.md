# humer

# What it does

# Compatible devices

# Prerequisites

# Installation

## Config

Configuration of the associated devices is stored in the config file.
The file must be deployed in the application's main directory:

```bash
/root/.humer/devices
```

The config is a plaintext, tab-separated values file of the following structure:

* Device type - must be one of: "sensor", "smartplug",
* Device location - must be one of: "bedroom", "bathroom", "kitchen", "livingroom",
* MAC address - six uppercase hexadecimals, separated by ':',
* Ping interval - integer, in minutes.

E.g.

```text
sensor              bathroom             A4:C1:38:CF:06:FF  1
sensor              kitchen              A4:C1:38:A4:08:94  1
sensor              livingroom           A4:C1:38:64:27:47  5
sensor              bedroom              A4:C1:38:A5:B2:D0  5
```

# How it works

# Adding new device

# Resources utilisation

# TODOs

* '/usr/bin/humer' for starting/stopping or otherwise accessing sensors
* Jenkins pipeline: shellcheck, installation testing, code testing, deployment
* sqlite3 to docker, not on OS
* Squash commits when 1.0.0 is reached, disable working on master afterwards
* Is podman less resource-hungry than docker?
* install.sh - flags for forcing db removal, grafana removal
* unroot?
* Grafana as a code (terraform?)
* To log listing add OS logs, e.g. hdd usage
*  
