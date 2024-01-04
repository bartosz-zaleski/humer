#!/usr/bin/env bats

setup() {
    cd humer/
}

@test "humer.sh - input parameters" {

    run sh /code/humer/humer.sh
    [[ "${lines[*]}" =~ ERROR:\ No\ parameters\ supplied ]]
    [ "$status" -eq 1 ]

    run sh /code/humer/humer.sh gibberish
    [[ "${lines[*]}" =~ ERROR:\ Incorrect\ parameter:\ gibberish ]]
    [ "$status" -eq 1 ]

    run sh /code/humer/humer.sh --help
    [[ "${lines[*]}" =~ Usage ]]
    [ "$status" -eq 0 ]

    run sh /code/humer/humer.sh --help --version
    [[ "${lines[*]}" =~ Usage ]]
    [ "$status" -eq 0 ]

    run sh /code/humer/humer.sh --version
    [[ "${lines[*]}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
    [ "$status" -eq 0 ]

    run sh /code/humer/humer.sh --version --help
    [[ "${lines[*]}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
    [ "$status" -eq 0 ]

    run sh /code/humer/humer.sh --devices_file non-existent validate_devices_file
    [[ "${lines[*]}" =~ Incorrect ]]

    devices_file=$(mktemp)
    echo "dsf dsf asdf asdf dsaf " > "$devices_file"
    run sh /code/humer/humer.sh --devices_file "$devices_file" validate_devices_file
    [[ "${lines[*]}" =~ Incorrect ]]

    devices_file=$(mktemp)
    echo "sensor kitchen AA:AA:AA:AA:AA:AA 1" > "$devices_file"
    echo "" >> "$devices_file"
    echo "sensor kitchen AA:AA:AA:AA:AA:AA 1" >> "$devices_file"
    echo "" >> "$devices_file"
    run sh /code/humer/humer.sh --devices_file "$devices_file" validate_devices_file
    echo ">>> ${lines[*]} <<<" >&3
    [[ "${lines[*]}" =~ Correct ]]
}
