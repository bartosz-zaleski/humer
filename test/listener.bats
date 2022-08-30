#!/usr/bin/env bats

@test "addition using bc" {
  run echo "Oi"
  [ "$status" -eq 0 ]
}

@test "Writing to the listener" {
    mkfifo 'AA:AA:AA:AA'
    ../shell/listener.sh 'AA:AA:AA:AA'

    echo "" > 'AA:AA:AA:AA'
}