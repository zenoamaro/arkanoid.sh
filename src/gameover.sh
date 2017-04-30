#!/usr/bin/env bash

gameoverSoundThread=

gameover-mode() {
  KEY=
  sound gameover
  gameoverSoundThread=$!

  draw-centered $((screenH / 2 - 1)) 3 "You failed to liberate your fellow brothers.  But you may get to try again"
  draw-centered $((screenH / 2 + 1)) 1 "Press <space> to get revenge"

  LOOP=gameover-loop
}

gameover-loop() {
  if [[ $KEY == ' ' ]]; then
    kill-thread $gameoverSoundThread
    title-mode
  else
    render
  fi
}
