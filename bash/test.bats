#!/usr/bin/env bats

setup() {
    cd humer/
}

@test "humer.sh - input parameters" {

    run sh /code/humer/humer.sh --help
    echo ">>> ${lines[*]} <<<" >&3
    [ "$status" -eq 0 ]
}
