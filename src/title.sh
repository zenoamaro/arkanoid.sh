#!/usr/bin/env bash

titleSoundThread=

title-mode() {
  tput clear

  sound title
  titleSoundThread=$!
  title-screen
  render
  LOOP=title-loop
}

title-loop() {
  if [[ $KEY == ' ' ]]; then
    kill-thread $titleSoundThread
    game-mode
  fi
}

title-screen() {
  draw-picture $(center 140) 5 title
  local text="Use Q and P to move  –  Press <space> to start"
  draw $(center ${#text}) $((screenH - 5)) 3 "$text"
}
