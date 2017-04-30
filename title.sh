#!/usr/bin/env bash

soundThread=

title-mode() {
  tput clear
  sound title
  cat gfx/title.ans
  LOOP=title-loop
}

title-loop() {
  if [[ $KEY == ' ' ]]; then
    terminate-all-threads
    game-mode
  fi
}