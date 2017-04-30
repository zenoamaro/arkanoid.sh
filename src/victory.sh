#!/usr/bin/env bash

victorySoundThread=

victory-mode() {
  KEY=
  sound victory
  victorySoundThread=$!

  draw-centered $((screenH / 2 - 1)) 3 "The citizens have been stirred!  The freedom is unstoppable!  Hurray!"
  draw-centered $((screenH / 2 + 1)) 1 "Press <space> to get reminisce about the old days"

  LOOP=victory-loop
}

victory-loop() {
  if [[ $KEY == ' ' ]]; then
    kill-thread $victorySoundThread
    title-mode
  else
    render
  fi
}
