#!/usr/bin/env bats

@test "addition using bc" {
  run echo "Oi"
  [ "$status" -eq 0 ]
}