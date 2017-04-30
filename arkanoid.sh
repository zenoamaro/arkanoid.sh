#!/usr/bin/env bash
source config.sh
source util.sh
source game.sh

PLATFORM=$(uname -s)
TTY=
KEY=

setup() {
  TTY=$(stty -g)
  stty -echo
  tput civis
  tput clear
  trap teardown EXIT INT
  trap loop ALRM
  generate-bricks
}

teardown() {
  terminate-all-threads
  trap exit ALRM
  stty "$TTY"
  tput cvvis
  tput sgr0
  tput clear
  sleep "$DELAY"
  exit
}

input() {
  read -rs -n1 KEY || true
}

setup

sound title 
soundThread=$!
cat gfx/title.ans
read -n1
kill-thread $soundThread

tput clear
sound start
loop

while :; do
  input
done
