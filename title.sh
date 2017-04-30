#!/usr/bin/env bash

soundThread=

title-mode() {
  tput clear
  sound title
  soundThread=$!
  cat gfx/title.ans
  LOOP=title-loop
}

title-loop() {
  if [[ $KEY == ' ' ]]; then
    kill-thread $soundThread  
    game-mode
  fi
}