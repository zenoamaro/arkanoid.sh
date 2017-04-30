#!/usr/bin/env bash

threads=()

keep-thread() {
  local pid=$!
  threads+=("$pid")
  echo $pid
}

kill-thread() {
  local pid=$1
  (kill -PIPE "$pid" || true) > /dev/null 2>&1
}

terminate-all-threads() {
  for index in "${!threads[@]}"; do
    kill-thread "${threads["$index"]}"
    unset threads["$index"]
  done
  threads=()
}


