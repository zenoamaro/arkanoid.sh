#!/usr/bin/env bash
source config.sh
source src/util.sh
source src/input.sh
source src/gfx.sh
source src/sound.sh
source src/title.sh
source src/game.sh
source src/gameover.sh

LOOP=

setup() {
  trap teardown EXIT INT
  trap start-loop ALRM
  gfx-setup
  sound-setup
}

teardown() {
  gfx-teardown
  sound-teardown
  terminate-all-threads
  trap exit ALRM
  sleep "$DELAY"
  exit
}

start-loop() {
  $LOOP
  (sleep $DELAY && kill -ALRM $$) &
}

setup
title-mode
start-loop
start-input-handler