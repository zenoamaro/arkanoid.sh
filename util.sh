#!/usr/bin/env bash

threads=()

start-thread() {
  "$@" &
  local pid=$!
  threads+=("$pid")
}

kill-thread() {
  local pid=$1
  (kill -PIPE "$thread" || true) > /dev/null 2>&1
}

terminate-all-threads() {
  for thread in "${threads[@]}"; do
    kill-thread "$thread"
  done
}


