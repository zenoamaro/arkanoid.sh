#!/usr/bin/env bash

playSound=

sound-setup() {
  if which afplay; then
    playSound='sound-afplay'
  elif which paplay; then
    playSound='sound-paplay'
  elif which aplay; then
    playSound='sound-aplay'
  else
    playSound='sound-beep'
  fi
}

sound-teardown() {
  true
}

sound() {
  local sound=sound/$1.mp3
  $playSound "$sound"
}

sound-afplay() {
  afplay "$*" &
}

sound-paplay() {
  paplay "$*" &
}

sound-aplay() {
  aplay "$*" &
}

sound-beep() {
  echo -en '\a' &
}