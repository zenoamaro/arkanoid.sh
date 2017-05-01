#!/usr/bin/env bash

titleSoundThread=
titleScreen=()

# for A in $(seq 0 39); do perl -e "printf '%.0f ', cos($A / 3) * 6"; done
# for A in $(seq 0 39); do perl -e "printf '%.0f ', cos($A / 6) * 6"; done
sin=(
  3 3 2 2 1 -0 -1 -2 -3 -3 -3 -3 -2 -1 -0 1 2 2 3 3 3 2 2 1 1 -0 -1 -2 -3 -3 -3 -3 -2 -1 0 0 1 2
  3 3 2 1 -1 -2 -4 -5 -6 -6 -5 -4 -2 -0 2 3 5 6 6 6 5 3 1 -1 -3 -4 -5 -6 -6 -5 -4 -2 0 1 2
) sinc=${#sin[@]}

title-mode() {
  KEY=
  tput clear

  sound title
  titleSoundThread=$!

  draw-centered $((SCREEN_HEIGHT - 7)) 3 "Free the citizens from oppression"
  draw-centered $((SCREEN_HEIGHT - 5)) 1 "Use Q and P to move the paddle  –  Press <space> to start"

  readarray -t titleScreen < gfx/title.ans
  titleScreenOffset=$(center 140)

  LOOP=title-loop
}

title-loop() {
  if [[ $KEY == ' ' ]]; then
    kill-thread $titleSoundThread
    game-mode
  else
    local y=5
    for line in "${titleScreen[@]}"; do
      local i=$(((frame / 2 + y) % sinc))
      local x=$((titleScreenOffset + sin["$i"]))
      draw "$x" "$y" 0 "\e[1K$line\e[K"
      ((y++))
    done
    render
  fi
}
