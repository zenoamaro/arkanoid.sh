#!/usr/bin/env bash
source config.sh
source util.sh
source title.sh
source game.sh

PLATFORM=$(uname -s)
TTY=
KEY=
LOOP=

setup() {
  TTY=$(stty -g)
  stty -echo
  tput civis
  trap teardown EXIT INT
  trap loop ALRM
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

loop() {
  $LOOP
  (sleep $DELAY && kill -ALRM $$) &
}

setup
title-mode
loop

while :; do
  read -rs -n1 KEY || true
  if [[ -z $KEY ]]; then KEY=' '; fi
done
