#!/usr/bin/env bash
source config.sh
source util.sh
source game.sh

PLATFORM=$(uname -s)
TTY=
KEY=

score=0
screenW=$(tput cols) screenH=$(tput lines) screenC=$((screenW*screenH))
ballSize=1 ballX=$((screenW/2-1)) ballY=$((screenH-1))
paddleSize=15 paddleX=$((screenW/2-paddleSize/2)) paddleY=$((screenH-1)) 
ballSpeedX=1 ballSpeedY=-1 paddleSpeed=0 maxPaddleSpeed=4 paddleSafeArea=4
brickSize=${#BRICK} bricks=()
framebuffer=

setup() {
  TTY=$(stty -g)
  stty raw -echo
  tput civis
  tput clear
  trap teardown EXIT
  trap loop ALRM
  generate-bricks
}

teardown() {
  trap exit ALRM
  stty "$TTY"
  tput cvvis
  tput sgr0
  sleep $DELAY
  exit
}

input() {
  read -rs -n1 KEY || true
}

setup
sound start
loop

while :; do
  input
done
