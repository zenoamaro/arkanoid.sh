#!/usr/bin/env bash

originalTTY=
framebuffer=
frame=0

screenW=$(tput cols)
screenH=$(tput lines)

gfx-setup() {
  originalTTY=$(stty -g)
  stty raw -echo
  tput civis  
  tput rmam
}

gfx-teardown() {
  stty "$originalTTY"
  tput cvvis
  tput smam
  tput sgr0
  tput clear
}

render() {
  echo -en "${framebuffer}"
  framebuffer=
  ((frame++))
}

draw() {
  local x=$1
  local y=$2
  local color=$3
  local str=${*:4}
  framebuffer="${framebuffer}\e[$((y+1));$((x+1))H\e[$((color+90));m${str}\e[m"
}

draw-picture() {
  local x=$1
  local y=$2
  local filename=gfx/$3.ans
  local contents=()
  local offset=0
  readarray -t contents < "$filename"
  for line in "${contents[@]}"; do
    draw "$x" "$((y+offset))" 0 "$line"
    ((offset++))
  done
}

erase() {
  local x=$1
  local y=$2
  local len=$3
  framebuffer="${framebuffer}\e[$((y+1));$((x+1))H\e[${len}X"
}

repeat() {
  local c=$1
  local n=$2
  printf "%0.s$c" $(seq 1 "$n")
}

center() {
  local size=$1
  local padding=$(( (screenW-size) / 2 ))
  if ((padding < 0)); then ((padding = 0)); fi
  echo $padding
}