#!/usr/bin/env bash
source config.sh
source util.sh
source input.sh
source gfx.sh
source sound.sh
source title.sh
source game.sh

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