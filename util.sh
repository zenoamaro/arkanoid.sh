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

draw() {
  local x=$1
  local y=$2
  local color=$3
  local str=${*:4}
  framebuffer="${framebuffer}\e[$((y+1));$((x+1))H\e[$((color+90));m${str}\e[m"
}

erase() {
  local x=$1
  local y=$2
  local len=$3
  framebuffer="${framebuffer}\e[$((y+1));$((x+1))H$(repeat ' ' "$len")"
}

repeat() {
  local c=$1
  local n=$2
  printf "%0.s$c" $(seq 1 "$n")
}

sound() {
  local sound=sound/$1.mp3
  case $PLATFORM in
    Darwin) start-thread afplay "$sound";;
    Linux) start-thread paplay "$sound";;
    *) echo -en '\a';;
  esac
}