#!/usr/bin/env bash

titleSoundThread=

titleScreen=()
readarray -t titleScreen < gfx/title.ans
titleScreenOffset=$(center 140)

# for A in $(seq 0 39); do perl -e "printf '%.0f ', cos($A / 3) * 6"; done
sin=(
  3 3 2 2 1 -0 -1 -2 -3 -3 -3 -3 -2 -1 -0 1 2 2 3 3 3 2 2 1 1 -0 -1 -2 -3 -3 -3 -3 -2 -1 0 0 1 2
  3 3 2 1 -1 -2 -4 -5 -6 -6 -5 -4 -2 -0 2 3 5 6 6 6 5 3 1 -1 -3 -4 -5 -6 -6 -5 -4 -2 0 1 2
) sinc=${#sin[@]}

title-mode() {
  tput clear

  sound title
  titleSoundThread=$!

  local text="Use Q and P to move  –  Press <space> to start"
  draw "$(center ${#text})" "$((screenH - 5))" 3 "$text"

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
