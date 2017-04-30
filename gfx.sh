#!/usr/bin/env bash

originalTTY=
framebuffer=

gfx-setup() {
  originalTTY=$(stty -g)
  stty -echo
  tput civis  
}

gfx-teardown() {
  stty "$originalTTY"
  tput cvvis
  tput sgr0
  tput clear
}

render() {
  echo -en "${framebuffer}"
  framebuffer=
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
